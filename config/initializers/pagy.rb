require "pagy"

# Default page size; overridable per-request via ?per_page= (capped in Paginatable).
Pagy::DEFAULT[:limit] = 25
