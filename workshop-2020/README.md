<h1 align="center">Finding security vulnerabilities in C/C++ with CodeQL</h1>
<h5 align="center">@adityasharad, moderated by @aeisenberg @geoffw0 @mathiasvp @xcorail</h5>

<p align="center">
  <a href="#mega-prerequisites">Prerequisites</a> •  
  <a href="#books-resources">Resources</a>
</p>

> CodeQL is GitHub's expressive language and engine for code analysis, which allows you to explore source code to find bugs and security vulnerabilities. During this beginner-friendly workshop, you will learn to write queries in CodeQL to find use-after-free vulnerabilities in open-source C/C++ code.

## :mega: Prerequisites
- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://help.semmle.com/codeql/codeql-for-vscode/procedures/setting-up.html).
- You do _not_ need to install the CodeQL CLI: the extension will handle this for you.
- Clone this repository:
  ```
  git clone --recursive https://github.com/githubuniverseworkshops/codeql
  ```
  - **Please don't forget `--recursive`:** This allows you to obtain the standard CodeQL query libraries, which are included as a Git submodule of this repository.
  - **What if I forgot to add `--recursive`?** If you've already cloned the repository, please set up the submodule by running:
    ```
    git submodule update --init --remote
    ```
- Open the repository in Visual Studio Code: **File** > **Open** (or **Open Folder**) > Browse to the checkout of `githubuniverseworkshops/codeql`.
- Import the [CodeQL database](https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2020/codeql-cpp-workshop-uaf.zip) to be used in the workshop:
  - Click the **CodeQL** rectangular icon in the left sidebar.
  - Place your mouse over **Databases**, and click the icon labelled `Download Database`.
  - Copy and paste this URL into the box: https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2020/codeql-cpp-workshop-uaf.zip
  - Click on the database name, and click **Set Current Database**.
- You're ready! Proceed to the [workshop](workshop.md).

## :books: Resources
- For more advanced CodeQL development in future, you may wish to set up the [CodeQL starter workspace](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/#using-the-starter-workspace) for all languages.
- [CodeQL overview](https://codeql.github.com/docs/codeql-overview/)
- [CodeQL for C/C++](https://codeql.github.com/docs/codeql-language-guides/codeql-for-cpp/)
- [Analyzing data flow in C/C++](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-cpp/)
- [Using the CodeQL extension for VS Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/)
- CodeQL on [GitHub Learning Lab](https://lab.github.com/search?q=codeql)
- CodeQL on [GitHub Security Lab](https://codeql.com)

## License

The code in this repository is licensed under the [MIT License](LICENSE) by GitHub.
