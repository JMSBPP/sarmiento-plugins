# Typecheck a package name or .ipkg file
typecheck file:
    pack typecheck {{file}}

# Typecheck the local library package (all modules under src/)
typecheck-src:
    pack typecheck sarmiento-plugins
