import 'diet_program.dart';

/// The reviewed diet-program catalog.
///
/// Editorial rules (see docs/CONTENT_REVIEW_CHECKLIST.md):
/// - no approach is described as universally superior;
/// - every program lists limitations and who should seek guidance first;
/// - evidence references are real, verifiable publications;
/// - extreme restriction, detoxes, and prolonged fasting are excluded.
abstract final class DietCatalog {
  static DietProgram byId(String id) =>
      all.firstWhere((d) => d.id == id, orElse: () => all.first);

  static const List<DietProgram> all = [
    DietProgram(
      id: 'balanced',
      name: 'Balanced diet',
      tagline: 'Flexible, varied eating with no food groups off-limits',
      overview:
          'A balanced approach spreads calories across all food groups with '
          'an emphasis on vegetables, fruit, whole grains, lean protein and '
          'unsaturated fats. It is the default starting point for most '
          'people because it needs no special rules.',
      foodPattern:
          'Half the plate vegetables and fruit, a quarter whole grains, a '
          'quarter protein, plus dairy or fortified alternatives and small '
          'amounts of added fats.',
      benefits: [
        'Easy to follow with normal family meals',
        'Covers most nutrient needs without supplements',
        'Adapts to any cuisine or budget',
      ],
      limitations: [
        'Progress toward specific goals can be slower without structure',
        'Portion awareness is still needed for weight goals',
      ],
      seekGuidanceFirst: [
        'Anyone with a diagnosed medical condition affecting diet',
      ],
      sustainability: 5,
      difficulty: 1,
      sampleDay: {
        'Breakfast': 'Oatmeal with banana, peanut butter and milk',
        'Lunch': 'Chicken and vegetable rice bowl',
        'Dinner': 'Baked fish, potatoes and a large salad',
        'Snack': 'Yogurt with fruit',
      },
      encouraged: [
        'Vegetables and fruit',
        'Whole grains',
        'Lean proteins and legumes',
        'Nuts, seeds and olive oil',
      ],
      limited: [
        'Sugar-sweetened drinks',
        'Heavily processed snacks',
        'Excess alcohol',
      ],
      nutrientGaps: ['Usually none when varied'],
      evidence: [
        EvidenceRef(
          title: 'Dietary Guidelines for Americans 2020–2025',
          source: 'USDA & HHS',
          year: '2020',
        ),
      ],
      recipeTags: ['balanced', 'general'],
    ),
    DietProgram(
      id: 'high_protein',
      name: 'High-protein diet',
      tagline: 'Extra protein to support satiety and muscle',
      overview:
          'Raises protein to roughly 1.6–2.2 g per kg of body weight while '
          'keeping other food groups. Often used to preserve muscle during '
          'weight loss or support strength training.',
      foodPattern:
          'Protein at every meal (eggs, poultry, fish, dairy, tofu, '
          'legumes) with vegetables, fruit and whole grains around it.',
      benefits: [
        'Protein increases satiety, which can make calorie goals easier',
        'Supports muscle retention when losing weight and muscle gain when '
            'training',
      ],
      limitations: [
        'Higher grocery costs for protein foods',
        'Very high intakes offer no extra benefit for most people',
      ],
      seekGuidanceFirst: [
        'People with kidney disease or reduced kidney function',
      ],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Greek yogurt with berries and granola',
        'Lunch': 'Grilled chicken salad with chickpeas',
        'Dinner': 'Lean beef stir-fry with rice and vegetables',
        'Snack': 'Cottage cheese or a boiled egg',
      },
      encouraged: [
        'Eggs, poultry, fish, lean meat',
        'Dairy or soy products',
        'Legumes and tofu',
      ],
      limited: ['Processed meats', 'Deep-fried protein'],
      nutrientGaps: ['Fiber if plants are crowded out'],
      evidence: [
        EvidenceRef(
          title:
              'International Society of Sports Nutrition position stand: '
              'protein and exercise',
          source: 'J Int Soc Sports Nutr',
          year: '2017',
        ),
      ],
      recipeTags: ['high_protein', 'balanced'],
      macroSplit: MacroSplit(proteinPct: 30, carbsPct: 40, fatPct: 30),
    ),
    DietProgram(
      id: 'mediterranean',
      name: 'Mediterranean-style diet',
      tagline: 'Plant-forward eating with olive oil, fish and whole grains',
      overview:
          'Modeled on traditional eating patterns of the Mediterranean '
          'region: abundant vegetables, legumes, whole grains, olive oil, '
          'nuts, moderate fish and dairy, and little red or processed meat.',
      foodPattern:
          'Plants and olive oil daily, fish and seafood at least twice a '
          'week, poultry and dairy in moderation, red meat rarely.',
      benefits: [
        'One of the most-studied patterns for heart health',
        'Emphasizes enjoyable, unprocessed food',
        'No calorie counting required to start',
      ],
      limitations: [
        'Olive oil, nuts and fish can be costly in some regions',
        'Less structured, which some people find harder to follow',
      ],
      seekGuidanceFirst: [
        'People on blood-thinning medication (fish oil intake)',
      ],
      sustainability: 5,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Whole-grain toast with tomato, olive oil and cheese',
        'Lunch': 'Lentil soup with salad and bread',
        'Dinner': 'Grilled fish with roasted vegetables and couscous',
        'Snack': 'A handful of nuts and fruit',
      },
      encouraged: [
        'Olive oil as the main fat',
        'Vegetables, fruit, legumes',
        'Fish and seafood',
        'Whole grains and nuts',
      ],
      limited: ['Red and processed meat', 'Added sugar', 'Refined grains'],
      nutrientGaps: ['Generally few; iron for some people'],
      evidence: [
        EvidenceRef(
          title:
              'Primary prevention of cardiovascular disease with a '
              'Mediterranean diet (PREDIMED)',
          source: 'N Engl J Med',
          year: '2018',
          note: 'Republished analysis',
        ),
      ],
      recipeTags: ['mediterranean', 'balanced', 'pescatarian'],
    ),
    DietProgram(
      id: 'low_carb',
      name: 'Low-carbohydrate diet',
      tagline: 'Fewer refined carbs, more protein and healthy fats',
      overview:
          'Reduces carbohydrate to roughly 20–40% of calories, focusing on '
          'protein, non-starchy vegetables and healthy fats. Less strict '
          'than keto and easier to sustain for many people.',
      foodPattern:
          'Non-starchy vegetables, protein and fats at each meal; smaller '
          'portions of whole-grain or starchy sides.',
      benefits: [
        'Can improve satiety and reduce snacking for some people',
        'Often simplifies cutting sugary foods and drinks',
      ],
      limitations: [
        'Energy for high-intensity exercise may dip initially',
        'Whole grains and fruit still matter — cutting them entirely is '
            'unnecessary',
      ],
      seekGuidanceFirst: [
        'People with diabetes on glucose-lowering medication',
      ],
      sustainability: 3,
      difficulty: 3,
      sampleDay: {
        'Breakfast': 'Vegetable omelet with cheese',
        'Lunch': 'Chicken salad with olive-oil dressing',
        'Dinner': 'Pork chop with cauliflower rice and greens',
        'Snack': 'Nuts or plain yogurt',
      },
      encouraged: [
        'Non-starchy vegetables',
        'Eggs, fish, poultry, meat',
        'Nuts, seeds, olive oil, avocado',
      ],
      limited: [
        'Sugar and sweets',
        'White bread, rice and pasta in large portions',
      ],
      nutrientGaps: ['Fiber', 'B vitamins if grains are cut sharply'],
      evidence: [
        EvidenceRef(
          title:
              'Effect of low-fat vs low-carbohydrate diet on weight loss '
              '(DIETFITS)',
          source: 'JAMA',
          year: '2018',
          note: 'Both diets performed similarly; adherence mattered most',
        ),
      ],
      recipeTags: ['low_carb', 'high_protein'],
      macroSplit: MacroSplit(proteinPct: 30, carbsPct: 30, fatPct: 40),
    ),
    DietProgram(
      id: 'keto',
      name: 'Ketogenic diet',
      tagline: 'Very low carb, high fat — a strict, structured approach',
      overview:
          'Restricts carbohydrate to roughly 5–10% of calories so the body '
          'shifts toward fat and ketones for fuel. A demanding pattern that '
          'requires planning to stay nutritionally adequate.',
      foodPattern:
          'Fats and protein form each meal (eggs, fish, meat, cheese, oils, '
          'nuts) with non-starchy vegetables; grains, most fruit, and sugary '
          'foods are avoided.',
      benefits: [
        'Rapid early progress can be motivating for some people',
        'Very structured rules suit people who prefer clear limits',
      ],
      limitations: [
        'Common early side effects (fatigue, headache) during adaptation',
        'Long-term evidence in the general population is limited',
        'Social eating and dining out become harder',
      ],
      seekGuidanceFirst: [
        'People with diabetes on medication (hypoglycemia risk)',
        'People with kidney, liver or gallbladder conditions',
        'Anyone pregnant or breastfeeding',
      ],
      sustainability: 2,
      difficulty: 5,
      sampleDay: {
        'Breakfast': 'Scrambled eggs with spinach and cheese',
        'Lunch': 'Tuna salad with avocado and olive oil',
        'Dinner': 'Roast chicken thigh with buttered broccoli',
        'Snack': 'Macadamia nuts',
      },
      encouraged: [
        'Eggs, fish, poultry, meat',
        'Non-starchy vegetables',
        'Olive oil, butter, nuts, seeds, avocado',
      ],
      limited: [
        'Grains, bread, rice, pasta',
        'Most fruit',
        'Sugar in all forms',
        'Starchy vegetables',
      ],
      nutrientGaps: ['Fiber', 'Vitamin C', 'Magnesium', 'Folate'],
      evidence: [
        EvidenceRef(
          title:
              'Ketogenic diets for weight loss: systematic review and '
              'network meta-analysis of randomized trials',
          source: 'BMJ',
          year: '2020',
          note: 'Diet differences shrink at 12 months; adherence dominates',
        ),
      ],
      recipeTags: ['keto', 'low_carb'],
      macroSplit: MacroSplit(proteinPct: 20, carbsPct: 10, fatPct: 70),
    ),
    DietProgram(
      id: 'vegetarian',
      name: 'Vegetarian diet',
      tagline: 'Plant-based eating that includes dairy and eggs',
      overview:
          'Excludes meat, poultry and fish while keeping eggs and dairy. '
          'Well-planned vegetarian diets are nutritionally adequate for '
          'adults according to major dietetic associations.',
      foodPattern:
          'Legumes, tofu, eggs and dairy provide protein; whole grains, '
          'vegetables, fruit, nuts and seeds fill the plate.',
      benefits: [
        'Typically high in fiber and phytonutrients',
        'Lower grocery costs when built on legumes and grains',
        'Aligns with many ethical and environmental values',
      ],
      limitations: [
        'Iron from plants is absorbed less efficiently',
        'Protein needs slightly more planning at first',
      ],
      seekGuidanceFirst: ['People with iron-deficiency anemia'],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Yogurt with muesli and fruit',
        'Lunch': 'Chickpea curry with rice',
        'Dinner': 'Vegetable and tofu stir-fry with noodles',
        'Snack': 'Boiled egg or trail mix',
      },
      encouraged: [
        'Legumes, tofu, tempeh',
        'Eggs and dairy',
        'Whole grains, nuts, seeds',
        'Vegetables and fruit',
      ],
      limited: [
        'Meat, poultry, fish (excluded)',
        'Heavily processed meat substitutes',
      ],
      nutrientGaps: ['Iron', 'Zinc', 'Omega-3 (EPA/DHA)'],
      evidence: [
        EvidenceRef(
          title:
              'Position of the Academy of Nutrition and Dietetics: '
              'vegetarian diets',
          source: 'J Acad Nutr Diet',
          year: '2016',
        ),
      ],
      recipeTags: ['vegetarian', 'vegan'],
    ),
    DietProgram(
      id: 'vegan',
      name: 'Vegan diet',
      tagline: 'Fully plant-based, no animal products',
      overview:
          'Excludes all animal products. Nutritionally adequate for adults '
          'when well planned, but requires attention to vitamin B12 and a '
          'few other nutrients.',
      foodPattern:
          'Legumes, soy foods, whole grains, nuts, seeds, vegetables and '
          'fruit, with fortified foods or supplements for B12.',
      benefits: [
        'Highest fiber intake of common patterns',
        'Strong alignment with environmental and ethical goals',
      ],
      limitations: [
        'Vitamin B12 supplementation is required, not optional',
        'Eating out and social meals need more planning',
      ],
      seekGuidanceFirst: [
        'Anyone pregnant or breastfeeding',
        'People with a history of disordered eating (restriction risk)',
      ],
      sustainability: 3,
      difficulty: 4,
      sampleDay: {
        'Breakfast': 'Overnight oats with soy milk, chia and banana',
        'Lunch': 'Lentil and vegetable soup with bread',
        'Dinner': 'Tofu adobo-style with rice and greens',
        'Snack': 'Hummus with vegetable sticks',
      },
      encouraged: [
        'Legumes, tofu, tempeh, edamame',
        'Whole grains',
        'Nuts and seeds',
        'Fortified plant milks',
      ],
      limited: ['All animal products (excluded)'],
      nutrientGaps: [
        'Vitamin B12 (supplement needed)',
        'Iron',
        'Calcium',
        'Omega-3',
        'Iodine',
      ],
      evidence: [
        EvidenceRef(
          title:
              'Position of the Academy of Nutrition and Dietetics: '
              'vegetarian diets',
          source: 'J Acad Nutr Diet',
          year: '2016',
        ),
      ],
      recipeTags: ['vegan'],
    ),
    DietProgram(
      id: 'pescatarian',
      name: 'Pescatarian diet',
      tagline: 'Vegetarian plus fish and seafood',
      overview:
          'A vegetarian pattern that adds fish and seafood, combining '
          'plant-forward eating with the omega-3 fats found in oily fish.',
      foodPattern:
          'Fish or seafood a few times a week over a base of vegetables, '
          'legumes, whole grains, eggs and dairy.',
      benefits: [
        'Covers omega-3 needs more easily than strict vegetarian diets',
        'Flexible middle ground for people reducing meat',
      ],
      limitations: [
        'Quality fish can be expensive',
        'Large predatory fish should be limited due to mercury',
      ],
      seekGuidanceFirst: ['Anyone pregnant (fish species selection)'],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Oatmeal with fruit and nuts',
        'Lunch': 'Sardine or tuna sandwich with salad',
        'Dinner': 'Grilled bangus (milkfish) with rice and vegetables',
        'Snack': 'Yogurt or fruit',
      },
      encouraged: [
        'Fish and seafood',
        'Legumes and eggs',
        'Vegetables, fruit, whole grains',
      ],
      limited: ['Meat and poultry (excluded)', 'High-mercury fish'],
      nutrientGaps: ['Iron for some people'],
      evidence: [
        EvidenceRef(
          title:
              'Fish consumption and cardiovascular health: AHA science advisory',
          source: 'Circulation',
          year: '2018',
        ),
      ],
      recipeTags: ['pescatarian', 'vegetarian', 'vegan'],
    ),
    DietProgram(
      id: 'whole_food',
      name: 'Whole-food diet',
      tagline: 'Minimally processed food, cooked mostly from scratch',
      overview:
          'Prioritizes food close to its natural form — vegetables, fruit, '
          'whole grains, legumes, eggs, fish, meat — while minimizing '
          'ultra-processed products.',
      foodPattern:
          'Cook from whole ingredients; when buying packaged food, prefer '
          'short ingredient lists.',
      benefits: [
        'Naturally reduces added sugar, sodium and refined oils',
        'Ultra-processed food is linked with higher energy intake in trials',
      ],
      limitations: [
        'More cooking time than convenience eating',
        '"Processed" is a spectrum — some processed foods (frozen '
            'vegetables, canned beans, yogurt) are excellent choices',
      ],
      seekGuidanceFirst: [],
      sustainability: 4,
      difficulty: 3,
      sampleDay: {
        'Breakfast': 'Eggs with tomatoes and whole-grain bread',
        'Lunch': 'Home-cooked chicken tinola with rice',
        'Dinner': 'Baked fish with roasted root vegetables',
        'Snack': 'Fruit and nuts',
      },
      encouraged: [
        'Whole vegetables and fruit',
        'Whole grains and legumes',
        'Plain dairy, eggs, fish, meat',
      ],
      limited: [
        'Ultra-processed snacks and drinks',
        'Instant meals as a default',
      ],
      nutrientGaps: ['Usually none'],
      evidence: [
        EvidenceRef(
          title:
              'Ultra-processed diets cause excess calorie intake and weight '
              'gain: randomized controlled trial',
          source: 'Cell Metab (Hall et al.)',
          year: '2019',
        ),
      ],
      recipeTags: ['whole_food', 'balanced'],
    ),
    DietProgram(
      id: 'high_fiber',
      name: 'High-fiber diet',
      tagline: 'Focus on plants, grains and legumes for gut health',
      overview:
          'Targets 25–38 g of fiber daily from vegetables, fruit, legumes '
          'and whole grains — the intake range associated with better '
          'digestive and cardiometabolic health.',
      foodPattern:
          'Legumes or whole grains at most meals, vegetables twice a day, '
          'fruit as the default snack.',
      benefits: [
        'Strong evidence for heart and gut health',
        'High satiety per calorie',
      ],
      limitations: [
        'Increase fiber gradually and drink water to avoid discomfort',
      ],
      seekGuidanceFirst: ['People with IBS, IBD or other digestive conditions'],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Oatmeal with chia and fruit',
        'Lunch': 'Monggo (mung bean) stew with brown rice',
        'Dinner': 'Whole-wheat pasta with vegetables and beans',
        'Snack': 'Popcorn or an apple',
      },
      encouraged: [
        'Legumes',
        'Whole grains',
        'Vegetables and fruit with skins',
        'Nuts and seeds',
      ],
      limited: ['Refined grains', 'Juice instead of whole fruit'],
      nutrientGaps: ['Usually none'],
      evidence: [
        EvidenceRef(
          title:
              'Carbohydrate quality and human health: series of systematic '
              'reviews and meta-analyses',
          source: 'The Lancet (Reynolds et al.)',
          year: '2019',
        ),
      ],
      recipeTags: ['high_fiber', 'balanced', 'vegetarian'],
    ),
    DietProgram(
      id: 'low_sodium',
      name: 'Low-sodium diet',
      tagline: 'Less salt, more herbs, spices and fresh food',
      overview:
          'Keeps sodium under about 2300 mg per day by cooking fresh, '
          'limiting processed and cured foods, and seasoning with herbs, '
          'citrus and spices instead of salt.',
      foodPattern:
          'Fresh or frozen ingredients, rinsed canned goods, low-sodium '
          'sauces; soy sauce, patis and salty condiments measured, not poured.',
      benefits: [
        'Supports healthy blood pressure',
        'Encourages fresh cooking skills',
      ],
      limitations: [
        'Restaurant and convenience food make it harder',
        'Taste adaptation takes a few weeks',
      ],
      seekGuidanceFirst: [
        'People on diuretics or blood-pressure medication (do not change '
            'medication without your physician)',
      ],
      sustainability: 3,
      difficulty: 3,
      sampleDay: {
        'Breakfast': 'Oatmeal with fruit',
        'Lunch': 'Grilled chicken with rice and steamed vegetables',
        'Dinner': 'Fish sinigang made with fresh tamarind, less patis',
        'Snack': 'Unsalted nuts or fruit',
      },
      encouraged: [
        'Fresh vegetables and fruit',
        'Fresh meat and fish',
        'Herbs, spices, citrus, vinegar',
      ],
      limited: [
        'Cured and processed meat',
        'Instant noodles and canned soup',
        'Salty condiments',
      ],
      nutrientGaps: ['Iodine if iodized salt is heavily reduced'],
      evidence: [
        EvidenceRef(
          title: 'Guideline: sodium intake for adults and children',
          source: 'World Health Organization',
          year: '2012',
        ),
      ],
      recipeTags: ['low_sodium', 'whole_food', 'balanced'],
    ),
    DietProgram(
      id: 'dash',
      name: 'DASH-style eating',
      tagline: 'The blood-pressure-friendly research diet',
      overview:
          'DASH (Dietary Approaches to Stop Hypertension) emphasizes '
          'vegetables, fruit, whole grains and low-fat dairy while limiting '
          'sodium, added sugar and saturated fat. Extensively studied for '
          'blood-pressure support.',
      foodPattern:
          '4–5 servings each of vegetables and fruit daily, whole grains, '
          'low-fat dairy, lean protein, nuts and legumes several times a week.',
      benefits: [
        'Strong randomized-trial evidence for lowering blood pressure',
        'Nutritionally complete without supplements',
      ],
      limitations: ['Serving-count structure takes effort to learn'],
      seekGuidanceFirst: [
        'People on blood-pressure medication (dosage must only be changed '
            'by your physician)',
      ],
      sustainability: 4,
      difficulty: 3,
      sampleDay: {
        'Breakfast': 'Low-fat yogurt with banana and oats',
        'Lunch': 'Turkey and vegetable wrap with fruit',
        'Dinner': 'Grilled fish, brown rice and two vegetable sides',
        'Snack': 'Unsalted nuts',
      },
      encouraged: [
        'Vegetables and fruit',
        'Whole grains',
        'Low-fat dairy',
        'Nuts and legumes',
      ],
      limited: ['Sodium', 'Sugary drinks and sweets', 'Fatty and cured meats'],
      nutrientGaps: ['Usually none'],
      evidence: [
        EvidenceRef(
          title:
              'A clinical trial of the effects of dietary patterns on blood '
              'pressure (DASH)',
          source: 'N Engl J Med (Appel et al.)',
          year: '1997',
        ),
      ],
      recipeTags: ['dash', 'low_sodium', 'balanced'],
    ),
    DietProgram(
      id: 'calorie_deficit',
      name: 'Calorie-deficit plan',
      tagline: 'Structured, gradual weight loss with any foods',
      overview:
          'A moderate calorie deficit (about 10–20% below estimated needs) '
          'with flexible food choices. NutriGuide caps automatic deficits '
          'and never recommends eating below its safety minimum.',
      foodPattern:
          'Normal meals with portion awareness; protein and fiber '
          'prioritized to stay satisfied.',
      benefits: [
        'Works with any cuisine or preference',
        'Gradual pace supports maintaining results',
      ],
      limitations: [
        'Requires consistent logging to be effective',
        'Weight fluctuates daily — trends matter, not single days',
      ],
      seekGuidanceFirst: [
        'Anyone with a history of disordered eating',
        'Anyone pregnant or breastfeeding (weight loss is generally not '
            'advised)',
      ],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Eggs with vegetables and toast',
        'Lunch': 'Chicken rice bowl, extra vegetables',
        'Dinner': 'Fish with potatoes and salad',
        'Snack': 'Fruit or yogurt',
      },
      encouraged: [
        'Protein at each meal',
        'High-volume vegetables',
        'Water as default drink',
      ],
      limited: ['Liquid calories', 'Grazing without logging'],
      nutrientGaps: ['Watch overall variety at lower intakes'],
      evidence: [
        EvidenceRef(
          title: 'Obesity management: AACE/ACE clinical practice guidelines',
          source: 'Endocr Pract',
          year: '2016',
        ),
      ],
      recipeTags: ['balanced', 'high_protein', 'general'],
    ),
    DietProgram(
      id: 'weight_gain',
      name: 'Healthy weight-gain plan',
      tagline: 'A gentle calorie surplus built on nutritious food',
      overview:
          'Adds roughly 300 kcal above estimated needs using energy-dense '
          'but nutritious foods, ideally combined with strength training so '
          'weight gained includes muscle.',
      foodPattern:
          'Three meals plus 2–3 substantial snacks; healthy fats (nuts, '
          'oils, avocado) and protein raise energy density.',
      benefits: [
        'Structured approach for people who struggle to gain',
        'Emphasizes nutritious calories over junk calories',
      ],
      limitations: [
        'Appetite can lag — consistency matters more than big meals',
      ],
      seekGuidanceFirst: [
        'Anyone with unexplained weight loss (see a physician first)',
        'Anyone recovering from an eating disorder',
      ],
      sustainability: 4,
      difficulty: 2,
      sampleDay: {
        'Breakfast': 'Peanut-butter banana oatmeal with whole milk',
        'Lunch': 'Rice with chicken adobo and vegetables, extra rice',
        'Dinner': 'Beef and potato stew with bread',
        'Snack': 'Trail mix, smoothie with milk and oats',
      },
      encouraged: [
        'Nuts, nut butters, oils',
        'Whole milk and yogurt',
        'Rice, oats, potatoes',
        'Protein at each meal',
      ],
      limited: ['Filling up on zero-calorie drinks before meals'],
      nutrientGaps: ['Usually none'],
      evidence: [
        EvidenceRef(
          title:
              'International Society of Sports Nutrition position stand: '
              'nutrient timing',
          source: 'J Int Soc Sports Nutr',
          year: '2017',
        ),
      ],
      recipeTags: ['balanced', 'high_protein', 'general'],
    ),
    DietProgram(
      id: 'maintenance',
      name: 'Maintenance plan',
      tagline: 'Hold steady and build consistency',
      overview:
          'Eating at estimated energy needs to maintain current weight '
          'while focusing on food quality, routine and enjoyable habits.',
      foodPattern:
          'Balanced plate at regular times; flexibility for social meals '
          'with awareness of the weekly picture.',
      benefits: [
        'Lowest-pressure approach — ideal after a loss or gain phase',
        'Builds the habits that make results last',
      ],
      limitations: ['Progress is measured in consistency, not scale changes'],
      seekGuidanceFirst: [],
      sustainability: 5,
      difficulty: 1,
      sampleDay: {
        'Breakfast': 'Whatever balanced breakfast you enjoy',
        'Lunch': 'Half vegetables, quarter protein, quarter grains',
        'Dinner': 'Family meal with portion awareness',
        'Snack': 'Fruit, yogurt or nuts',
      },
      encouraged: [
        'Regular meal times',
        'Vegetables daily',
        'Enjoyable movement',
      ],
      limited: ['All-or-nothing thinking'],
      nutrientGaps: ['None specific'],
      evidence: [
        EvidenceRef(
          title: 'Dietary Guidelines for Americans 2020–2025',
          source: 'USDA & HHS',
          year: '2020',
        ),
      ],
      recipeTags: ['balanced', 'general'],
    ),
    DietProgram(
      id: 'intermittent_fasting',
      name: 'Intermittent fasting',
      tagline: 'Time-boxed eating windows: 12:12 up to 16:8',
      overview:
          'Limits eating to a daily window (12 to 8 hours). Research '
          'suggests results are similar to ordinary calorie reduction — it '
          'is a scheduling tool, not magic. NutriGuide supports gentle '
          'schedules only and never encourages prolonged fasting.',
      foodPattern:
          'Normal balanced meals inside the eating window; water, plain '
          'coffee or tea outside it.',
      benefits: [
        'Simplifies the day for people who dislike tracking',
        'Can reduce late-night snacking',
      ],
      limitations: [
        'Evidence shows similar results to ordinary calorie reduction',
        'Hunger and irritability are common in the first weeks',
        'Not appropriate for everyone — see the guidance list',
      ],
      seekGuidanceFirst: [
        'People with diabetes on medication (hypoglycemia risk)',
        'Anyone pregnant or breastfeeding',
        'Anyone with a history of disordered eating',
        'People on medication requiring food',
      ],
      sustainability: 3,
      difficulty: 3,
      sampleDay: {
        'First meal (12:00)': 'Rice bowl with chicken and vegetables',
        'Snack (15:30)': 'Fruit and nuts',
        'Dinner (19:00)': 'Fish with vegetables and rice',
        'Window closes (20:00)': 'Water, tea or black coffee after this',
      },
      encouraged: [
        'Balanced meals in the window',
        'Hydration during the fast',
        'Gentle schedules (12:12–16:8)',
      ],
      limited: [
        'Prolonged fasts (not supported)',
        'Compensatory bingeing in the window',
      ],
      nutrientGaps: ['Total intake can drop unintentionally — watch protein'],
      evidence: [
        EvidenceRef(
          title:
              'Effect of time-restricted eating on weight loss (TREAT '
              'randomized clinical trial)',
          source: 'JAMA Intern Med (Lowe et al.)',
          year: '2020',
        ),
      ],
      recipeTags: ['balanced', 'general'],
      supportsFasting: true,
    ),
    DietProgram(
      id: 'custom_macro',
      name: 'Custom macro plan',
      tagline: 'Set your own protein, carb and fat targets',
      overview:
          'For experienced users who want direct control over macronutrient '
          'targets. NutriGuide validates your split, warns about extreme '
          'settings, and keeps the calorie safety floor.',
      foodPattern: 'Any foods that fit your chosen macro targets.',
      benefits: [
        'Full flexibility for athletes and experienced trackers',
        'Works with a coach\'s external prescription',
      ],
      limitations: [
        'Requires understanding of your own needs',
        'Extreme splits are rejected for safety',
      ],
      seekGuidanceFirst: [
        'Anyone using macros prescribed for a medical condition',
      ],
      sustainability: 3,
      difficulty: 4,
      sampleDay: {
        'Breakfast': 'Built from your targets',
        'Lunch': 'Built from your targets',
        'Dinner': 'Built from your targets',
        'Snack': 'Optional, from remaining macros',
      },
      encouraged: ['Whole-food sources of each macro'],
      limited: ['Splits outside safe bounds (validated automatically)'],
      nutrientGaps: ['Depends on chosen split'],
      evidence: [
        EvidenceRef(
          title: 'Dietary Reference Intakes: macronutrient ranges (AMDR)',
          source: 'Institute of Medicine',
          year: '2005',
        ),
      ],
      recipeTags: ['general', 'balanced', 'high_protein'],
    ),
    DietProgram(
      id: 'custom_schedule',
      name: 'Custom meal schedule',
      tagline: 'Your timing, your meal count — from 2 to 6 meals',
      overview:
          'Keeps NutriGuide\'s balanced nutrition targets but lets you '
          'choose exactly how many meals and when — useful for shift work, '
          'family schedules or religious practice.',
      foodPattern:
          'Nutrition targets are spread across your chosen meal slots.',
      benefits: [
        'Fits real schedules including night shifts',
        'Meal count has little effect on results — timing consistency helps '
            'adherence',
      ],
      limitations: ['Very few, this is a scheduling preference'],
      seekGuidanceFirst: ['People on medication requiring fixed meal times'],
      sustainability: 5,
      difficulty: 1,
      sampleDay: {
        'Slot 1': 'Balanced meal at your chosen time',
        'Slot 2': 'Balanced meal at your chosen time',
        'Slot 3': 'Balanced meal or snack at your chosen time',
      },
      encouraged: ['Consistent slot times', 'Protein in each slot'],
      limited: ['None specific'],
      nutrientGaps: ['None specific'],
      evidence: [
        EvidenceRef(
          title: 'Meal frequency and energy balance: a review',
          source: 'Br J Nutr (Bellisle et al.)',
          year: '1997',
        ),
      ],
      recipeTags: ['balanced', 'general'],
    ),
  ];
}
