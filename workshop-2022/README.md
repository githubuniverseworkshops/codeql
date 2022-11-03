# CodeQL workshop for Ruby: Finding open URL redirection vulnerabilities

<h5 align="center">@adityasharad and @rvermeulen</h5>

If you are attending this workshop at GitHub Universe, please follow the instructions below to prepare for the workshop in advance.

Closer to the workshop date, the detailed workshop steps will be available below, which the facilitators will guide you through.

## Contents

- Prerequisites and setup instructions
  - [On your local machine](#setup)
  - [On Codespaces](#setup-codespaces)
- [Workshop](#workshop)

## Prerequisites and setup instructions (on your local machine) <a id="setup"></a>

Please complete this section before the workshop, if possible.

- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/).
- You do _not_ need to install the CodeQL CLI: the extension will handle this for you.
- Clone this repository:
  ```
  git clone https://github.com/githubuniverseworkshops/codeql
  ```
  - Use `git pull origin main` to regularly keep this clone up to date with the latest state of the repository.
- Open the repository in Visual Studio Code: **File** > **Open** (or **Open Folder**) > Browse to the checkout of `githubuniverseworkshops/codeql`.
- Import the [CodeQL database](https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2022/codeql-ruby-workshop-opf-openproject.zip) to be used in the workshop:
  - Click the **CodeQL** rectangular icon in the left sidebar.
  - Place your mouse over **Databases**, and click the cloud-shaped icon labelled `Download Database`.
  - Copy and paste this URL into the box, then press **OK**/**Enter**: https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2022/codeql-ruby-workshop-opf-openproject.zip
  - The CodeQL extension will download the CodeQL CLI and the chosen database.
  - After the database is downloaded, it will appear in the left sidebar under **Databases**. Click on the database name, and click **Set Current Database**.
- Install the CodeQL library package for analyzing Ruby code.
  - From the Command Palette (`Cmd/Ctrl+Shift+P`), search for and run the command `CodeQL: Install Pack Dependencies`.
  - At the top of your VS Code window, type `github` in the box to filter the list.
  - Check the box next to `githubuniverseworkshops/codeql-workshop-2022-ruby`.
  - Click **OK**/**Enter**.
- Run a test CodeQL query:
  - Open the file [`workshop-2022/example.ql`](/workshop-2022/example.ql).
  - From the Command Palette (`Cmd/Ctrl+Shift+P`) or the right-click context menu, click the command `CodeQL: Run Query`.
  - After the query compiles and runs, you should see the results in a new `CodeQL Query Results` tab.
- Create a new file in the `workshop-2022` directory called `UrlRedirect.ql`. You'll develop this query during the workshop.

## Prerequisites and setup instructions (on Codespaces) <a id="setup-codespaces"></a>

Coming soon!

## Workshop <a id="workshop"></a>

Coming soon!
