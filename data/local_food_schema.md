# Local-Food CSV Schema & Import Workflow

For curating reviewable local-food datasets (e.g. Filipino dishes). Every row
is a **reviewed** entry. Estimated dishes must document their assumptions and
must never present invented values as laboratory data.

## CSV columns

| Column | Required | Type | Notes |
|---|---|---|---|
| `id` | yes | slug | Unique, lowercase_snake (e.g. `chicken_adobo`) |
| `name` | yes | text | Display name |
| `category` | yes | enum | grains, protein, dairy, vegetables, fruit, legumes, fats, dishes, snacks, beverages |
| `source` | yes | enum | `verified` (lab/USDA) or `recipeEstimate` |
| `source_ref` | yes | text | USDA FDC id for verified; dataset/version for estimates |
| `serving_name` | yes | text | e.g. "1 cup with sauce" |
| `serving_g` | yes | number | Grams per serving |
| `protein_g_100` | yes | number | Per 100 g |
| `carbs_g_100` | yes | number | Per 100 g |
| `fat_g_100` | yes | number | Per 100 g |
| `fiber_g_100` | no | number | Per 100 g |
| `sodium_mg_100` | no | number | Per 100 g |
| `kcal_100` | verified only | number | Published kcal; **omit for estimates** (computed via Atwater) |
| `allergens` | no | list | `;`-separated (peanut;milk;...) |
| `tags` | no | list | Diet tags (`;`-separated) matching diet recipe tags |
| `assumptions` | estimate only | text | Ingredient + serving assumptions shown in-app |
| `reviewed_by` | yes | text | Reviewer name/role |
| `last_reviewed` | yes | date | ISO date |
| `population` | no | text | Applicable country/population |
| `version` | yes | text | Dataset version |

## Rules (enforced by the importer)

1. **Verified** rows must include `kcal_100`; the importer checks it against the
   Atwater estimate (4·protein + 4·carbs + 9·fat, minus fiber allowance) and
   rejects rows outside tolerance.
2. **Estimate** rows must NOT include `kcal_100`; kcal is computed from macros
   so totals are always internally consistent, and `assumptions` is required.
3. No negative values; serving grams > 0.
4. `reviewed_by` and `last_reviewed` are mandatory (human review trail).

## Import workflow

1. Author/curate rows in a spreadsheet; export CSV to `data/local_foods.csv`.
2. A registered dietitian reviews and fills `reviewed_by` / `last_reviewed`.
3. Run the generator/importer, which validates the rules above and merges into
   the bundled dataset or the Firestore `/reference` collection. The current
   seed generator (`tool/generate_seed_data.mjs`) demonstrates the same
   validation for the bundled dataset.
4. Bump `version`; commit with the reviewer noted.

The bundled seed dataset already follows these rules: Filipino dishes are
`recipeEstimate`, kcal is Atwater-computed, and assumptions are shown in-app.
