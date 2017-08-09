# Add remote and do a fetch immediately
git remote add -f theme-indigo https://github.com/yscoder/hexo-theme-indigo.git

# Add subtree
git subtree add --prefix themes/indigo theme-indigo card --squash

# Enable tags page
hexo new page tags
# Then edit metadata in source/tags/index.md:
# layout: tags
# comments: false
# ---

# Enable categories page
hexo new page categories
# Then edit metadata in source/categories/index.md:
# layout: categories
# comments: false
# ---
