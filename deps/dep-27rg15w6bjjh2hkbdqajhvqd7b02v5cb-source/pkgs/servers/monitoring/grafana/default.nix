{ lib, buildGoModule, fetchurl, fetchFromGitHub, nixosTests, tzdata, wire }:

buildGoModule rec {
  pname = "grafana";
  version = "10.2.5";

  excludedPackages = [ "alert_webhook_listener" "clean-swagger" "release_publisher" "slow_proxy" "slow_proxy_mac" "macaron" "devenv" "modowners" ];

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "grafana";
    rev = "v${version}";
    hash = "sha256-7M+hr1FQFssC0QVQ61TzxbA1Wk+4Nc7Y/3u2ZQ/FJFY=";
  };

  srcStatic = fetchurl {
    url = "https://dl.grafana.com/oss/release/grafana-${version}.linux-amd64.tar.gz";
    hash = "sha256-tukcQeV/dUrJrJ1Gllq9qYY6C8YIvuiO2gD+AkX9Kn4=";
  };

  vendorHash = "sha256-8xA3+y8eF3vVs6crs9cVthbpGRHYzvBokxv5LjzsEJI=";

  nativeBuildInputs = [ wire ];

  postConfigure = ''
    # Generate DI code that's required to compile the package.
    # From https://github.com/grafana/grafana/blob/v8.2.3/Makefile#L33-L35
    wire gen -tags oss ./pkg/server
    wire gen -tags oss ./pkg/cmd/grafana-cli/runner

    GOARCH= CGO_ENABLED=0 go generate ./pkg/plugins/plugindef
    GOARCH= CGO_ENABLED=0 go generate ./kinds/gen.go
    GOARCH= CGO_ENABLED=0 go generate ./public/app/plugins/gen.go
    GOARCH= CGO_ENABLED=0 go generate ./pkg/kindsys/report.go

    # Work around `main module (github.com/grafana/grafana) does not contain package github.com/grafana/grafana/pkg/util/xorm`.
    # Apparently these files confuse the dependency resolution for the go builder implemented here.
    rm pkg/util/xorm/go.{mod,sum}

    # The testcase makes an API call against grafana.com:
    #
    # [...]
    # grafana> t=2021-12-02T14:24:58+0000 lvl=dbug msg="Failed to get latest.json repo from github.com" logger=update.checker error="Get \"https://raw.githubusercontent.com/grafana/grafana/main/latest.json\": dial tcp: lookup raw.githubusercontent.com on [::1]:53: read udp [::1]:36391->[::1]:53: read: connection refused"
    # grafana> t=2021-12-02T14:24:58+0000 lvl=dbug msg="Failed to get plugins repo from grafana.com" logger=plugin.manager error="Get \"https://grafana.com/api/plugins/versioncheck?slugIn=&grafanaVersion=\": dial tcp: lookup grafana.com on [::1]:53: read udp [::1]:41796->[::1]:53: read: connection refused"
    sed -i -e '/Request is not forbidden if from an admin/a t.Skip();' pkg/tests/api/plugins/api_plugins_test.go

    # Skip a flaky test (https://github.com/NixOS/nixpkgs/pull/126928#issuecomment-861424128)
    sed -i -e '/it should change folder successfully and return correct result/{N;s/$/\nt.Skip();/}'\
      pkg/services/libraryelements/libraryelements_patch_test.go


    # main module (github.com/grafana/grafana) does not contain package github.com/grafana/grafana/scripts/go
    rm -r scripts/go

    # Requires making API calls against storage.googleapis.com:
    #
    # [...]
    # grafana> 2023/08/24 08:30:23 failed to copy objects, err: Post "https://storage.googleapis.com/upload/storage/v1/b/grafana-testing-repo/o?alt=json&name=test-path%2Fbuild%2FTestCopyLocalDir2194093976%2F001%2Ffile2.txt&prettyPrint=false&projection=full&uploadType=multipart": dial tcp: lookup storage.googleapis.com on [::1]:53: read udp [::1]:36436->[::1]:53: read: connection refused
    # grafana> panic: test timed out after 10m0s
    rm pkg/build/gcloud/storage/gsutil_test.go
  '';

  ldflags = [
    "-s" "-w" "-X main.version=${version}"
  ];

  # Tests start http servers which need to bind to local addresses:
  # panic: httptest: failed to listen on a port: listen tcp6 [::1]:0: bind: operation not permitted
  __darwinAllowLocalNetworking = true;

  # On Darwin, files under /usr/share/zoneinfo exist, but fail to open in sandbox:
  # TestValueAsTimezone: date_formats_test.go:33: Invalid has err for input "Europe/Amsterdam": operation not permitted
  preCheck = ''
    export ZONEINFO=${tzdata}/share/zoneinfo
  '';

  postInstall = ''
    tar -xvf $srcStatic
    mkdir -p $out/share/grafana
    mv grafana-*/{public,conf,tools} $out/share/grafana/

    cp ./conf/defaults.ini $out/share/grafana/conf/
  '';

  passthru = {
    tests = { inherit (nixosTests) grafana; };
    updateScript = ./update.sh;
  };

  meta = with lib; {
    description = "Gorgeous metric viz, dashboards & editors for Graphite, InfluxDB & OpenTSDB";
    license = licenses.agpl3;
    homepage = "https://grafana.com";
    maintainers = with maintainers; [ offline fpletz willibutz globin ma27 Frostman ];
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "grafana-server";
  };
}
