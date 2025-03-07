{ wasm-bindgen-cli, ... }@args:
import ../generic.nix (
  args
  // {
    version = "16.4.14";
    hash = "sha256-9X4PLN5y1pJMNGL7o+NR/b3yUYch/VVEMmGmWbEO1CA=";
    vendorHash = "sha256-nJdtllxjem+EA77Sb1XKmrAaWh/8WrL3AuvVxgBRkxI=";
    pnpmHash = "sha256-+eOfGS9m3c9i7ccOS8q6KM0IrBIJZKlxx7h3qqxTJHE=";
    cargoHash = "sha256-6JYSW65ou8iC4/7AJVZ9+vpItxpJtaGFA4Nm3fgyHIs=";

    # wasm-bindgen-cli version must match the version of wasm-bindgen in Cargo.lock
    wasm-bindgen-cli = wasm-bindgen-cli.override {
      version = "0.2.95";
      hash = "sha256-prMIreQeAcbJ8/g3+pMp1Wp9H5u+xLqxRxL+34hICss=";
      cargoHash = "sha256-6iMebkD7FQvixlmghGGIvpdGwFNLfnUcFke/Rg8nPK4=";
    };
  }
)
