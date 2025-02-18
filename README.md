# CarbonLogLib

A Swift Library that contains basic model & service entities to keep track of a person's Carbon emissions in CO2 Kg equivalent

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
touch .git/hooks/pre-commit && chmod u+x .git/hooks/pre-commit
```

```shell
#!/bin/bash
git-format-staged --formatter "swiftformat stdin --stdinpath '{}'" "*.swift"
```
