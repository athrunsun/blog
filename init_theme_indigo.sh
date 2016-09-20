npm install hexo-renderer-less hexo-generator-feed hexo-generator-json-content hexo-deployer-git --save

# Enable tags page
hexo new page tags
# Then edit metadata in hexo/source/tags/index.md:
#layout: tags
#noDate: true
#comments: false
#---

# Add remote and do a fetch immediately
git remote add -f theme-indigo https://github.com/yscoder/hexo-theme-indigo.git

# Add subtree
git subtree add --prefix themes/indigo theme-indigo master --squash
