---
title: "Update personal blog hosted on github pages automatically with Travis CI"
date: 2016-10-09 09:12
categories: CI
tags:
- GitHub
- CI
- Travis
---
# Solution #1
Reference: [使用 Travis CI 自动更新 GitHub Pages](http://notes.iissnan.com/2016/publishing-github-pages-with-travis-ci/)

A sample configuration for my personal blog hosted on github pages would be,
```yaml
language: node_js

node_js:
  - "6"

env:
  global:
    - GH_REF: github.com/athrunsun/blog.git
    - secure: "xxxxxx"

branches:
  only:
  - master

# S: Build Lifecycle
install:
  - npm install

before_script:
  - git config --global user.name "xxx"
  - git config --global user.email "xxx@xxx.com"

script:
  - hexo clean
  - hexo generate

after_script:
  - cd public
  - git init
  - git add .
  - git commit -m "Update blog $(date +%Y-%m-%d,%H:%M:%S)"
  - git push -f -q "https://${GH_TOKEN}@${GH_REF}" master:gh-pages
# E: Build LifeCycle
```

But this requires us to install [travis command line client](https://github.com/travis-ci/travis.rb#command-line-client), encrypt our github API token and put the result in `env["global"]["secure"]`.

NOTE that we're using a **quite** push with `-q` option so that we won't leak our github API token. Also you can remove log permanently from Travis CI's UI once you see unintentional token leakages.

# Solution #2
Reference: [How to publish to Github Pages from Travis CI?](http://stackoverflow.com/questions/23277391/how-to-publish-to-github-pages-from-travis-ci)

A simpler solution (global environment variable `GITHUB_API_TOKEN` must be set beforehand in Travis CI's UI),
```yaml
language: node_js

node_js:
  - "6"

branches:
  only:
  - master

install:
  - npm install

script:
  - hexo clean
  - hexo generate

after_success:
  - cd public
  - git init
  - git add .
  - git -c user.name='travis' -c user.email='travis' commit -m "Update blog $(date +%Y-%m-%d,%H:%M:%S)"
  - git push -f -q "https://athrunsun:${GITHUB_API_TOKEN}@github.com/athrunsun/blog.git" master:gh-pages &> /dev/null
```

Here `&> /dev/null` means to [discard both standard output and error](http://askubuntu.com/questions/350208/what-does-2-dev-null-mean).

