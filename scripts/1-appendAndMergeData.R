#------------------------------------------------------------------------------------------------------#
# UK postcodes
# Yannis Galanakis; <galanakis.gian@gmail.com>
# Created: Feb 15, 2022
# Revised: Feb 21, 2022
# Objective: (1) Append postcode files, (2) assign rural/urban class, country and county names and (3) export to .csv
#------------------------------------------------------------------------------------------------------#

# Set Project Options ----
options(
  digits = 4, # Significant figures output
  scipen = 999, # Disable scientific notation
  repos = getOption("repos")["CRAN"]
)

# Load the necessary libraries ----
pacman::p_load(
  "tidyverse",
  "data.table",
  "dtplyr",
  "lubridate"
)

# append postcode .csv files ----
features <-list.files(path = 'data/input/postcodes/codes/', pattern='*.csv', recursive=TRUE,
                      full.names = TRUE) %>% 
  # read csv and rbind
  map_df(~read_csv(.x)%>% 
           # change the format to continue the rbind
           mutate(`ru11ind` = as.character(`ru11ind`),
                  `oseast1m`= as.character(`oseast1m`),
                  `osnrth1m`= as.character(`osnrth1m`)))
# rename
names(features)[names(features) == 'pcds'] <- 'postcode'

# keep only relevant columns to the final df
features_short <- features[c("postcode", "ru11ind", "oac11", "lat", "long", "cty", "ctry")]

# Output Area Classifications ----
oac11 <- fread(file = 'data/input/postcodes/dictionaries/2011_output_area_classification_uk.csv',
               select = c('OAC11', 'Supergroup', 'Group'), strip.white = TRUE,
               colClasses = c(OAC11 = 'character', Supergroup = 'character', Group = 'character'),
               data.table = FALSE)
names(oac11) <- c('oac11', 'oac_supergroup', 'oac_group')
oac11$oac_supergroup <- tolower(oac11$oac_supergroup)
oac11$oac_group <- tolower(oac11$oac_group)

# Rural Urban Classifications ----
ru11ind <- fread(file = 'data/input/postcodes/dictionaries/2011_rural_urban_indicator_gb.csv',
                 colClasses = list(character = c('RU11IND', 'RU11NM')),
                 data.table = FALSE)
names(ru11ind) <- c('ru11ind', 'ru11name')

# County and names ----
cty <- fread(file = 'data/input/postcodes/dictionaries/county_names_and_codes_uk.csv',
             colClasses = list(character = c('CTY21CD', 'CTY21NM')),
             data.table = FALSE) 
names(cty) <- c('cty', 'cty.name')

# County and names ----
ctry <- fread(file = 'data/input/postcodes/dictionaries/country_names_and_codes_uk.csv',
             colClasses = list(character = c('CTRY12CD', 'CTRY12NM')),
             data.table = FALSE)%>%
  select('CTRY12CD', 'CTRY12NM')
names(ctry) <- c('ctry', 'ctry.name')

# merge with above ----
descriptions <- features_short %>%
  left_join(y = oac11, by = 'oac11') %>%
  left_join(y = ru11ind, by = 'ru11ind') %>%
  left_join(y = cty, by = 'cty') %>%
  left_join(y = ctry, by = 'ctry')

# export as csv
fwrite(x = descriptions, file = "data/output/geographic.csv")
# export as rds
saveRDS(descriptions, file = "data/output/UKpostcodes.rds")
#------------------------------------------------------------------------------#

# remove identifier code variables
## it reduces the size of the resulting data frame 
descriptions_2 <- descriptions[-c(2:3, 6:7)]
