{
  lib,
  babel,
  buildPythonPackage,
  cairosvg,
  colorama,
  fetchFromGitHub,
  hatch-nodejs-version,
  hatch-requirements-txt,
  hatchling,
  jinja2,
  markdown,
  mkdocs,
  mkdocs-git-revision-date-localized-plugin,
  mkdocs-material-extensions,
  mkdocs-minify-plugin,
  mkdocs-redirects,
  mkdocs-rss-plugin,
  paginate,
  pillow,
  pygments,
  pymdown-extensions,
  pythonOlder,
  regex,
  requests,
  trove-classifiers,
}:

buildPythonPackage rec {
  pname = "mkdocs-material";
  version = "9.5.39";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "squidfunk";
    repo = "mkdocs-material";
    tag = version;
    hash = "sha256-ArCd7NbqvPw3kHJd4MG62FplgXwW1gFTfdCHZqfxuqU=";
  };

  nativeBuildInputs = [
    hatch-requirements-txt
    hatch-nodejs-version
    hatchling
    trove-classifiers
  ];

  propagatedBuildInputs = [
    babel
    colorama
    jinja2
    markdown
    mkdocs
    mkdocs-material-extensions
    paginate
    pygments
    pymdown-extensions
    regex
    requests
  ];

  optional-dependencies = {
    recommended = [
      mkdocs-minify-plugin
      mkdocs-redirects
      mkdocs-rss-plugin
    ];
    git = [
      # TODO: gmkdocs-git-committers-plugin
      mkdocs-git-revision-date-localized-plugin
    ];
    imaging = [
      cairosvg
      pillow
    ];
  };

  # No tests for python
  doCheck = false;

  pythonImportsCheck = [ "mkdocs" ];

  meta = with lib; {
    changelog = "https://github.com/squidfunk/mkdocs-material/blob/${src.rev}/CHANGELOG";
    description = "Material for mkdocs";
    downloadPage = "https://github.com/squidfunk/mkdocs-material";
    homepage = "https://squidfunk.github.io/mkdocs-material/";
    license = licenses.mit;
    maintainers = with maintainers; [ dandellion ];
  };
}
