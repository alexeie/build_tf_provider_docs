# Terraform Provider Documentation Builder

A utility to build a text documentation of a Terraform provider hosted on the [Terraform Registry](https://registry.terraform.io/). This is useful for feeding into LLMs for reference and providing exact and up-to-date knowledge.

## Features

*   Fetches provider documentation from the Terraform Registry.
*   Converts the documentation into a clean text format.
*   Outputs a single text file for easy use with LLMs.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   Python 3.8+
*   pip
*   venv

### Installation

1.  **Clone the repository:**

    ```sh
    git clone https://github.com/alexeie/build_tf_provider_docs.git
    cd build_tf_provider_docs
    ```

2.  **Create and activate a virtual environment:**

    Using `bash` or `zsh`:
    ```sh
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install the dependencies:**

    ```sh
    pip install -r requirements.txt
    ```

## Usage

To use the script, run it from the command line with the following arguments:

```sh
python main.py --provider <provider_name> --output <output_file>
```

For example:
```sh
python main.py --provider hashicorp/aws --output aws_provider_docs.txt
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
