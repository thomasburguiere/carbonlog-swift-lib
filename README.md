# carbonlog.lib

A description of this package.

## Generating & reading documention (WIP)

On a mac;
```shell
swift package generate-documentation

open .build/plugins/Swift-DocC/outputs/CarbonLogLib.doccarchive
```

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