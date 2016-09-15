---
title: Checkout multiple git working trees
date: 2016/03/24 14:00
categories: Git
---
The `worktree` sub command of git enable us to check out multiple branches, i.e. have multiple working trees at the same time.

This is really useful when I want to:
* Compare code from two branches in IDE instead of a GUI tool like smartgit.
* Perform a long running test on one branch and working on another branch.

See [this github blog post](https://github.com/blog/2042-git-2-5-including-multiple-worktrees-and-triangular-workflows) and [official documentation](https://git-scm.com/docs/git-worktree) for reference.