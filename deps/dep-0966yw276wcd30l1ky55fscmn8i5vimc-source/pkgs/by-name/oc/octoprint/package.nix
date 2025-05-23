{
  pkgs,
  stdenv,
  callPackage,
  lib,
  fetchFromGitHub,
  fetchPypi,
  python3,
  substituteAll,
  nix-update-script,
  nixosTests,
  # To include additional plugins, pass them here as an overlay.
  packageOverrides ? self: super: { },
}:
let

  py = python3.override {
    self = py;
    packageOverrides = lib.foldr lib.composeExtensions (self: super: { }) ([
      (
        # Due to flask > 2.3 the login will not work
        self: super: {
          werkzeug = super.werkzeug.overridePythonAttrs (oldAttrs: rec {
            version = "2.2.3";
            format = "setuptools";
            pyproject = null;
            src = fetchPypi {
              pname = "Werkzeug";
              inherit version;
              hash = "sha256-LhzMlBfU2jWLnebxdOOsCUOR6h1PvvLWZ4ZdgZ39Cv4=";
            };
            doCheck = false;
          });
          flask = super.flask.overridePythonAttrs (oldAttrs: rec {
            version = "2.2.5";
            format = "setuptools";
            src = fetchPypi {
              pname = "Flask";
              inherit version;
              hash = "sha256-7e6bCn/yZiG9WowQ/0hK4oc3okENmbC7mmhQx/uXeqA=";
            };
            doCheck = false;
          });
          flask-login = super.flask-login.overridePythonAttrs (oldAttrs: rec {
            version = "0.6.3";
            src = fetchPypi {
              pname = "Flask-Login";
              inherit version;
              hash = "sha256-XiPRSmB+8SgGxplZC4nQ8ODWe67sWZ11lHv5wUczAzM=";
            };
            build-system = [ self.setuptools ];
            doCheck = false; # DeprecationWarnings
          });

          netaddr = super.netaddr.overridePythonAttrs (oldAttrs: rec {
            version = "0.9.0";

            src = fetchPypi {
              pname = "netaddr";
              inherit version;
              hash = "sha256-e0b6mxotcf1d6eSjeE7zOXAKU6CMgEDwi69fEZTaASg=";
            };
          });
        })

      # Built-in dependency
      (self: super: {
        octoprint-filecheck = self.buildPythonPackage rec {
          pname = "OctoPrint-FileCheck";
          version = "2024.3.27";

          src = fetchFromGitHub {
            owner = "OctoPrint";
            repo = "OctoPrint-FileCheck";
            rev = version;
            sha256 = "sha256-2MK9whPpgwQC+WPbPf628Ocjz6t8HKozblP7dmjD7RQ=";
          };
          doCheck = false;
        };
      })

      # Built-in dependency
      (self: super: {
        octoprint-firmwarecheck = self.buildPythonPackage rec {
          pname = "OctoPrint-FirmwareCheck";
          version = "2021.10.11";

          src = fetchFromGitHub {
            owner = "OctoPrint";
            repo = "OctoPrint-FirmwareCheck";
            rev = version;
            hash = "sha256-wqbD82bhJDrDawJ+X9kZkoA6eqGxqJc1Z5dA0EUwgEI=";
          };
          doCheck = false;
        };
      })

      (self: super: {
        octoprint-pisupport = self.buildPythonPackage rec {
          pname = "OctoPrint-PiSupport";
          version = "2023.5.24";
          format = "setuptools";

          src = fetchFromGitHub {
            owner = "OctoPrint";
            repo = "OctoPrint-PiSupport";
            rev = version;
            hash = "sha256-KfkZXJ2f02G2ee+J1w+YQRKz+LSWwxVIIwmdevDGhew=";
          };

          # requires octoprint itself during tests
          doCheck = false;
          postPatch = ''
            substituteInPlace octoprint_pi_support/__init__.py \
              --replace /usr/bin/vcgencmd ${self.pkgs.libraspberrypi}/bin/vcgencmd
          '';
        };
      })

      (self: super: {
        octoprint = self.buildPythonPackage rec {
          pname = "OctoPrint";
          version = "1.10.3";

          src = fetchFromGitHub {
            owner = "OctoPrint";
            repo = "OctoPrint";
            rev = version;
            hash = "sha256-BToW1/AcQ01OK7RWZrkstX2M4+uKuL/wFB6HGkVUflk=";
          };

          propagatedBuildInputs =
            with self;
            [
              argon2-cffi
              blinker
              cachelib
              click
              colorlog
              emoji
              feedparser
              filetype
              flask
              flask-babel
              flask-assets
              flask-login
              flask-limiter
              frozendict
              future
              itsdangerous
              immutabledict
              jinja2
              markdown
              markupsafe
              netaddr
              netifaces
              octoprint-filecheck
              octoprint-firmwarecheck
              passlib
              pathvalidate
              pkginfo
              pip
              psutil
              pylru
              pyserial
              pyyaml
              regex
              requests
              rsa
              sarge
              semantic-version
              sentry-sdk
              setuptools
              tornado
              unidecode
              watchdog
              websocket-client
              werkzeug
              wrapt
              zeroconf
              zipstream-ng
              class-doc
              pydantic_1
            ]
            ++ lib.optionals stdenv.hostPlatform.isDarwin [ py.pkgs.appdirs ]
            ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [ octoprint-pisupport ];

          nativeCheckInputs = with self; [
            ddt
            mock
            pytestCheckHook
          ];

          patches = [
            # substitute pip and let it find out, that it can't write anywhere
            (substituteAll {
              src = ./pip-path.patch;
              pip = "${self.pip}/bin/pip";
            })

            # hardcore path to ffmpeg and hide related settings
            (substituteAll {
              src = ./ffmpeg-path.patch;
              ffmpeg = "${pkgs.ffmpeg}/bin/ffmpeg";
            })
          ];

          postPatch =
            let
              ignoreVersionConstraints = [
                "cachelib"
                "colorlog"
                "emoji"
                "immutabledict"
                "PyYAML"
                "sarge"
                "sentry-sdk"
                "watchdog"
                "wrapt"
                "zeroconf"
                "Flask-Login"
                "werkzeug"
                "flask"
                "Flask-Limiter"
                "blinker"
              ];
            in
            ''
              sed -r -i \
                ${lib.concatStringsSep "\n" (
                  map (e: ''-e 's@${e}[<>=]+.*@${e}",@g' \'') ignoreVersionConstraints
                )}
                setup.py
            '';

          dontUseSetuptoolsCheck = true;

          preCheck = ''
            export HOME=$(mktemp -d)
            rm pytest.ini
          '';

          disabledTests = [
            "test_check_setup" # Why should it be able to call pip?
          ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ "test_set_external_modification" ];
          disabledTestPaths = [
            "tests/test_octoprint_setuptools.py" # fails due to distutils and python3.12
          ];

          passthru = {
            inherit (self) python;
            updateScript = nix-update-script { };
            tests = {
              plugins = (callPackage ./plugins.nix { }) super self;
              inherit (nixosTests) octoprint;
            };
          };

          meta = with lib; {
            homepage = "https://octoprint.org/";
            description = "Snappy web interface for your 3D printer";
            mainProgram = "octoprint";
            license = licenses.agpl3Only;
            maintainers = with maintainers; [
              abbradar
              gebner
              WhittlesJr
              gador
            ];
          };
        };
      })
      (callPackage ./plugins.nix { })
      packageOverrides
    ]);
  };
in
with py.pkgs;
toPythonApplication octoprint
