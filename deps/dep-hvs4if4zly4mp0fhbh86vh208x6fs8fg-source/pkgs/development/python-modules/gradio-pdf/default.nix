{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatch-fancy-pypi-readme,
  hatch-requirements-txt,
  hatchling,
  gradio,
  gradio-client,
}:

buildPythonPackage rec {
  pname = "gradio-pdf";
  version = "0.0.17";
  pyproject = true;

  src = fetchPypi {
    pname = "gradio_pdf";
    inherit version;
    hash = "sha256-LoVcwE7eGcK5Nc6qKTnrnI+rNlsDbekhKUP+Fzq2SQ8=";
  };

  build-system = [
    hatch-fancy-pypi-readme
    hatch-requirements-txt
    hatchling
  ];

  dependencies = [ gradio-client ];

  buildInputs = [ gradio.sans-reverse-dependencies ];
  disallowedReferences = [ gradio.sans-reverse-dependencies ];

  pythonImportsCheck = [ "gradio_pdf" ];

  # tested in `gradio`
  doCheck = false;

  meta = {
    description = "Python library for easily interacting with trained machine learning models";
    homepage = "https://pypi.org/project/gradio-pdf/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ pbsds ];
  };
}
