<h1 align="center">Finding security vulnerabilities in C/C++ with CodeQL</h1>
<h5 align="center">@adityasharad</h3>

<p align="center">
  <a href="#mega-prerequisites">Prerequisites</a> •  
  <a href="#books-resources">Resources</a>
</p>

> CodeQL is GitHub's expressive language and engine for code analysis, which allows you to explore source code to find bugs and security vulnerabilities. During this beginner-friendly workshop, you will learn to write queries in CodeQL to find use-after-free vulnerabilities in open-source C/C++ code.

## :mega: Prerequisites
- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://help.semmle.com/codeql/codeql-for-vscode/procedures/setting-up.html).
- You do _not_ need to install the CodeQL CLI: the extension will handle this for you.
- Set up the [CodeQL starter workspace](https://help.semmle.com/codeql/codeql-for-vscode/procedures/setting-up.html#using-the-starter-workspace).
  - **Important:** Don't forget to use `git clone --recursive` or `git submodule update --init --remote` to update the submodules when you clone this repository. This allows you to obtain the standard CodeQL query libraries.
  - Open the starter workspace in Visual Studio Code: **File** > **Open Workspace** > Browse to `vscode-codeql-starter/vscode-codeql-starter.code-workspace` in your checkout of the starter workspace.
- Import the [CodeQL database](TODO) to be used in the workshop
  - Click the CodeQL icon in the left sidebar.
  - Place your mouse over **Databases**, and click `Download database`.
  - Use this URL: **TODO**.

## :books: Resources
- [Learning CodeQL](https://help.semmle.com/QL/learn-ql)
- [Learning CodeQL for C/C++](https://help.semmle.com/QL/learn-ql/cpp/ql-for-cpp.html)
- [Using the CodeQL extension for VS Code](https://help.semmle.com/codeql/codeql-for-vscode.html)
- More about CodeQL on [GitHub Security Lab](https://securitylab.github.com/tools/codeql)
- CodeQL on [GitHub Learning Lab](https://lab.github.com/search?q=codeql)
