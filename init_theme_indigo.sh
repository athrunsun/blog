# Add remote and do a fetch immediately
git remote add -f theme-indigo https://github.com/yscoder/hexo-theme-indigo.git

# Add subtree
git subtree add --prefix themes/indigo theme-indigo master --squash
