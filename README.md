# GitHub Automation Scripts

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [File Structure](#file-structure)
- [Setup](#setup)
- [Usage](#usage)
  - [Python Script](#python-script)
  - [Bash Script](#bash-script)
  - [PowerShell Script](#powershell-script)
  - [Batch Script](#batch-script)
- [Enhancements and Customizations](#enhancements-and-customizations)
- [Contributing](#contributing)
- [Reporting Bugs](#reporting-bugs)
- [Future Enhancements](#future-enhancements)
- [License](#license)

## Overview
These scripts automate the process of pushing changes to a GitHub repository, creating a pull request, and merging it automatically. They support Python, Bash, PowerShell, and Batch scripts.

## Prerequisites
- GitHub Personal Access Token (PAT) with necessary permissions.
- Python 3.x installed for the Python script.
- `requests` and `python-dotenv` Python packages (install via `requirements.txt`).

## File Structure
```plaintext
project/
├── scripts/
│   ├── push_to_github.py
│   ├── push_to_github.sh
│   ├── push_to_github.ps1
│   └── push_to_github.bat
├── requirements.txt
└── .env
```

## Setup
1. Clone the repository.
2. Navigate to the `project/scripts` directory.
3. Create a `.env` file in the root directory with the following content:
```plaintext
GITHUB_TOKEN=your_github_pat
```
4. Install the required Python packages:
```bash
pip install -r requirements.txt
```

## Usage

### Python Script
1. Navigate to the `scripts` directory.
2. Run the Python script:
```bash
python push_to_github.py
```
3. Follow the prompts to enter the necessary information (repository owner, repository name, file path to push, commit message, etc.).

### Bash Script
1. Navigate to the `scripts` directory.
2. Run the Bash script:
```bash
bash push_to_github.sh
```
3. Follow the prompts to enter the necessary information (repository owner, repository name, file path to push, commit message, etc.).

### PowerShell Script
1. Navigate to the `scripts` directory.
2. Run the PowerShell script:
```powershell
.\push_to_github.ps1
```
3. Follow the prompts to enter the necessary information (repository owner, repository name, file path to push, commit message, etc.).

### Batch Script
1. Navigate to the `scripts` directory.
2. Run the Batch script:
```cmd
push_to_github.bat
```
3. Follow the prompts to enter the necessary information (repository owner, repository name, file path to push, commit message, etc.).

## Enhancements and Customizations
- **Branch Name**: The default branch name is `automated-branch`. You can customize this by entering a different name when prompted.
- **File Path**: Specify the path of the file you want to push to the repository.
- **Commit Message**: Provide a meaningful commit message for the changes.
- **Logging**: All scripts include logging to track the progress and errors. You can modify the logging level and format as needed.
- **Handling Multiple Files**: Modify the scripts to handle multiple files if required.
- **Settings Profiles**: Save and load settings profiles to reuse configurations.
- **Help Section**: Access a help section with a menu for selecting options and settings.

## Contributing
1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -m 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a pull request.

## Reporting Bugs
If you encounter any bugs, please open an issue in the repository with detailed information about the problem.

## Future Enhancements
- Add support for handling multiple files.
- Implement additional error checks and validation.
- Extend the scripts to support more complex workflows and integrations.
- Include functionality to prompt users to like the repository before forking.
- Add popular badges to the README.md file.

## License
This project is licensed under the MIT License.
