
#-------------------------- ### Illuminate Report Card Data ###-------------------------------------

# Report card files (one per grade per school) need to be exported from Illuminate, 
# unzipped, and moved into GCS Storage/raw_data_storage/Illuminate-Report-Cards/Illuminate-Grades/SY/

gcs_global_bucket("raw_data_storage")

# Map get_objects function onto each item of the lists in order to move files from GCS bucket into local directory
map2(.x = schools_map,
     .y = grades_map,
     .f = ~get_objects_report_card(.x, .y))

# Identifying the files that were just moved into the local directory
file_list <- dir(path = here::here("data/flatfiles/rc_export/"), 
                 pattern = "\\.csv", full.names = TRUE)

# Read and save files from local directory as dataframes (one per school per grade) to a list 
grade_df_list <- file_list %>%
  map(read_csv) %>%
  map(clean_names)

# ------------------------- ### Pre-Algebra and Algebra Students ### --------------------------------
# Can be removed after 19-20

gcs_get_object("Illuminate-Report-Cards/prealg_students.csv",
               saveToDisk = "data/flatfiles/prealg_alg_students/prealg_students.csv",
               overwrite = TRUE)

gcs_get_object("Illuminate-Report-Cards/alg_students.csv",
               saveToDisk = "data/flatfiles/prealg_alg_students/alg_students.csv",
               overwrite = TRUE)

prealg_7 <- read_csv(file = here::here("data/flatfiles/prealg_alg_students/prealg_students.csv"))

alg_8 <- read_csv(file = here::here("data/flatfiles/prealg_alg_students/alg_students.csv"))


# ------------------------- ### DL Students with Modified Grading Scale ### --------------------------------
# Has to be updated once each year

# KAMS 
kams_title <- drive_find("KAMS Modified Grading: 19-20SY", n_max = 30)

kams_mod_grades <- bind_rows(ws(kams_title, "5th"), ws(kams_title, "6th"), 
                             ws(kams_title, "7th"), ws(kams_title, "8th"))

# KBCP 
kbcp_mod_grades <- read_sheet(ss = "https://docs.google.com/spreadsheets/d/17GAPma7f1e0EsXlphbeDFq7_fhK_1F5AQ7vdkH9DusE/edit#gid=0") %>%
  select(2) %>%
  clean_names()

# KACP
kacp_mod_grades <- read_sheet(ss = "https://docs.google.com/spreadsheets/d/1SwQhyioO9fULIz4gj_dhJ1_rktLiZHYzbqgsqkZ-Ov4/edit?ts=5d926196#gid=1171959828") %>%
  select(2) %>%
  clean_names()

# KAC
kac_title <- drive_find("KAC Modified Grading: 19-20SY", n_max = 30)

kac_mod_grades <- bind_rows(ws(kac_title, "5th"), ws(kac_title, "6th"),
                            ws(kac_title, "7th"), ws(kac_title, "8th"))

# All
# Note: don't bring in KOP or KAP because no GPA

all_mod_grades <- bind_rows(kams_mod_grades,
                            kbcp_mod_grades,
                            kacp_mod_grades,
                            kac_mod_grades) %>%
  filter(!is.na(id_number))


#-------------------------- ### SIS Roster Links from Deans List ###----------------------------------
# Has to be updated once each year OR if new gradebooks are added
# Only KAC, KACP, KAMS, KBCP, and KOA need to have updated final quarter grades on Deans List

map(.x = c("KAC", "KACP", "KAMS", "KBCP", "KOA"),
    .f = get_objects_roster_links)

# Gradebook names that link subjects to grades, needs to be downloaded from Deans List
sis_roster_links <- dir(path = here::here("data/flatfiles/DL_roster_links"), 
                        pattern = "19-20_roster_links", full.names = TRUE)

dl_rosters <- sis_roster_links %>%
  map_df(read_csv) %>%
  clean_names() %>% 
  filter(!is.na(gradebook_name_at_load)) %>% 
  select(sec_id = secondary_integration_id_at_load,
         gb_name = gradebook_name_at_load)
