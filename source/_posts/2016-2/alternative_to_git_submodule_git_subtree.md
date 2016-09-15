---
title: "(Rep) Alternatives To Git Submodule: Git Subtree"
date: 2016/02/10 16:48
categories: Git
---
[Original Post](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/)

By [Nicola Paolucci](http://blogs.atlassian.com/author/npaolucci/)

[Developer](http://blogs.atlassian.com/blog-cat/developer/)

On May 16, 2013

Update: I wrote a follow up [article on the power of Git subtree](https://developer.atlassian.com/blog/2015/05/the-power-of-git-subtree)

The Internet is full of articles on why you [should](http://codingkilledthecat.wordpress.com/2012/04/28/why-your-company-shouldnt-use-git-submodules/) [not](http://ayende.com/blog/4746/the-problem-with-git-submodules) [use](http://somethingsinistral.net/blog/git-submodules-are-probably-not-the-answer/) Git submodules. I mostly agree, although I am not so harsh in my evaluation. As I explained in a [previous post](http://blogs.atlassian.com/2013/03/git-submodules-workflows-tips/), `submodules` are useful for a few use cases but have several drawbacks.

Are there alternatives? The answer is: yes! There are (at least) two tools that can help track the history of software dependencies in your project while allowing you to keep using git:

* [git subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.txt)
* [google repo](https://code.google.com/p/git-repo/)

In this post I will be looking at `git subtree` and show why it is an improvement – albeit not perfect – over `git submodule`.

As a working example I run to my usual use case. How do I easily store and keep up to date the vim plugins used in [my dotfiles](https://bitbucket.org/durdn/cfg)?

### Why use subtree instead of submodule?
There are several reasons why you might find `subtree` better to use:

* Management of a simple workflow is easy.
* Older version of `git` are supported (even before `v1.5.2`).
* The sub-project’s code is available right after the `clone` of the super project is done.
* `subtree` does not require users of your repository to learn anything new, they can ignore the fact that you are using `subtree` to manage dependencies.
* `subtree` does not add new metadata files like `submodules` doe (i.e. `.gitmodule`).
* Contents of the module can be modified without having a separate repository copy of the dependency somewhere else.

In my opinion the drawbacks are acceptable:

* You must learn about a new merge strategy (i.e. `subtree`).
* Contributing code back `upstream` for the sub-projects is slightly more complicated.
* The responsibility of not mixing super and sub-project code in commits lies with you.

### How to use git subtree?
`git subtree` is available in stock version of `git` available since May 2012 – `1.7.11`+. The version installed by [homebrew](http://mxcl.github.io/homebrew/) on OSX already has subtree properly wired but on some platforms you might need to follow the [installation instructions](https://github.com/git/git/blob/master/contrib/subtree/INSTALL).

Let me show you the canonical example of tracking a vim plug-in using `git subtree`.

#### The quick and dirty way without remote tracking
If you just want a couple of one liners to cut and paste just read this paragraph.

First add the `subtree` at a specified `prefix` folder:
```shell
git subtree add --prefix .vim/bundle/tpope-vim-surround https://bitbucket.org/vim-plugins-mirror/vim-surround.git master --squash
```

(The common practice is to not store the entire history of the sub-project in your main repository, but If you want to preserve it just omit the `-squash` flag.)

The above command produces this output:
```shell
git fetch https://bitbucket.org/vim-plugins-mirror/vim-surround.git master
warning: no common commits
remote: Counting objects: 338, done.
remote: Compressing objects: 100% (145/145), done.
remote: Total 338 (delta 101), reused 323 (delta 89)
Receiving objects: 100% (338/338), 71.46 KiB, done.
Resolving deltas: 100% (101/101), done.
From https://bitbucket.org/vim-plugins-mirror/vim-surround.git
* branch            master     -} FETCH_HEAD
Added dir '.vim/bundle/tpope-vim-surround'
```

As you can see this records a `merge commit` by squashing the whole history of the `vim-surround` repository into a single one:
```shell
1bda0bd [3 minutes ago] (HEAD, stree) Merge commit 'ca1f4da9f0b93346bba9a430c889a95f75dc0a83' as '.vim/bundle/tpope-vim-surround' [Nicola Paolucci]
ca1f4da [3 minutes ago] Squashed '.vim/bundle/tpope-vim-surround/' content from commit 02199ea [Nicola Paolucci]
```

If after a while you want to update the code of the plugin from the `upstream` repository you can just `subtree pull`:
```shell
git subtree pull --prefix .vim/bundle/tpope-vim-surround https://bitbucket.org/vim-plugins-mirror/vim-surround.git master --squash
```

This is very quick and painless but the commands are slightly lengthy and hard to remember. We can make the commands shorter by adding the sub-project as a remote.

#### Adding the sub-project as a remote
Adding the subtree as a remote allows us to refer to it in shorter form:
```shell
git remote add -f tpope-vim-surround https://bitbucket.org/vim-plugins-mirror/vim-surround.git
```

Now we can add the subtree (as before), but now we can refer to the remote in short form:
```shell
git subtree add --prefix .vim/bundle/tpope-vim-surround tpope-vim-surround master --squash
```

The command to update the sub-project at a later date becomes:
```shell
git fetch tpope-vim-surround master
git subtree pull --prefix .vim/bundle/tpope-vim-surround tpope-vim-surround master --squash
```

#### Contributing back to upstream
We can freely commit our fixes to the sub-project in our local working directory now.

When it’s time to contribute back to the `upstream` project we need to fork the project and add it as another remote:
```shell
git remote add durdn-vim-surround ssh://git@bitbucket.org/durdn/vim-surround.git
```

Now we can use the `subtree push` command like the following:
```shell
git subtree push --prefix=.vim/bundle/tpope-vim-surround/ durdn-vim-surround master

git push using:  durdn-vim-surround master
Counting objects: 5, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 308 bytes, done.
Total 3 (delta 2), reused 0 (delta 0)
To ssh://git@bitbucket.org/durdn/vim-surround.git
  02199ea..dcacd4b  dcacd4b21fe51c9b5824370b3b224c440b3470cb -} master
```

After this we’re ready and we can open a `pull-request` to the maintainer of the package.

#### Without using the subtree command
`git subtree` is different from the [subtree merge strategy](https://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html). You can still use the merge strategy even if for some reason `git subtree` is not available. Here is how you would go about it:

Add the dependency as a simple [git remote](https://github.com/git/git/blob/master/contrib/subtree/INSTALL):
```shell
git remote add -f tpope-vim-surround https://bitbucket.org/vim-plugins-mirror/vim-surround.git
```

Before reading the contents of the dependency into the repository it’s important to record a merge so that we can track the entire tree history of the plug-in up to this point:
```shell
git merge -s ours --no-commit tpope-vim-surround/master
```

Which outputs:
```shell
Automatic merge went well; stopped before committing as requested
```

We then read the content of the latest tree-object in the plugin repository into our working directory ready to be committed:
```shell
git read-tree --prefix=.vim/bundle/tpope-vim-surround/ -u tpope-vim-surround/master
```

Now we can commit (and it will be a merge commit that will preserve the history of the tree we read):
```shell
git ci -m"[subtree] adding tpope-vim-surround"

[stree 779b094] [subtree] adding tpope-vim-surround
```

When we want to update the project we can now `pull` using the `subtree` merge strategy:
```shell
git pull -s subtree tpope-vim-surround master
```

### Conclusions
After having used `submodule` for a while I appreciate `git subtree` much more, lots of `submodule` problems are superseded and solved by `subtree`. As usual, with all things `git`, there is a learning curve to make the most of the feature.

Follow me [@durdn](http://twitter.com/durdn) for more Git rocking. And check out [Atlassian Stash](http://www.atlassian.com/software/stash/overview) if you’re looking for a killer tool to manage your Git repos.

**Update: I just wrote a [new article on the power of Git subtree](https://developer.atlassian.com/blog/2015/05/the-power-of-git-subtree).**