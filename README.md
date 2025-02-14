# carbonlog.lib

A description of this package.

## Autoformatting (Optional)

### Install tools
```shell
$ brew install swiftformat
$ npm install --global git-format-staged
```
### git `pre-commit` hook

```shell
#!/bin/bash
git-format-staged --formatter "swiftformat stdin --stdinpath '{}'" "*.swift"
```