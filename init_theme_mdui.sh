yarn add prismjs

# Add remote and do a fetch immediately
git remote add -f theme-mdui https://github.com/Halyul/hexo-theme-mdui.git

# Add subtree
git subtree add --prefix themes/mdui theme-mdui master --squash
