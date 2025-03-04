###########################################
# Cafe Sales Data Cleaning
###########################################

# Load Required Packages

# install.packages("tidyverse") 
library(tidyverse)
# install.packages("openxlsx")
library(openxlsx) # to save as an excel workbook


# Read Data & Define Missing Values
cafe_data <- read_csv("R/2025_03_01_Data_Cleaning_ProjectR/dirty_cafe_sales.csv",
                      na = c("", "ERROR", "UNKNOWN"))

view(cafe_data) 


# Rename Columns (Standardizing Names)
cafe_data <- cafe_data %>% 
  rename(transaction_ID = `Transaction ID`,
         price_per_unit = `Price Per Unit`,
         total_spent = `Total Spent`,
         payment_method = `Payment Method`,
         transaction_date = `Transaction Date`)


# Convert Date Column to Proper Format
cafe_data <- cafe_data %>% 
  mutate(transaction_date = mdy(transaction_date))


###########################################
# Missing Data Summary for Messy Data
###########################################

# Calculate % Missing per Column
missing_proportion <- cafe_data %>%
  summarise(across(everything(), ~ mean(is.na(.)) * 100))
print(missing_proportion)

# Calculate Overall % Missing
overall_missing_proportion <- mean(is.na(cafe_data)) * 100
print(overall_missing_proportion)  # ~1.3% Missing Data


###########################################
# Column-Wise Data Cleaning
###########################################

# 1. Clean `transaction_ID`
cafe_data <- cafe_data %>% 
  mutate(transaction_ID = str_replace(transaction_ID, "TXN_", ""))


view(cafe_data)


# 2. Clean `Item` Column (Fill Missing Values Based on Prices)
item_update <- function(cafe_data) {
  cafe_data %>% 
    mutate(Item = case_when(
      is.na(Item) & price_per_unit == 2.0 ~ "Coffee",
      is.na(Item) & price_per_unit == 1.5 ~ "Tea",
      is.na(Item) & price_per_unit == 5.0 ~ "Salad",
      is.na(Item) & price_per_unit == 1.0 ~ "Cookie",
      TRUE ~ Item))
}


# 3. Clean `Quantity` (Fill Missing Values Using `total_spent` / `price_per_unit`)
quant_update <- function(cafe_data) {
  cafe_data %>% 
    mutate(Quantity = case_when(
      is.na(Quantity) ~ total_spent / price_per_unit,
      TRUE ~ Quantity))
}


# 4. Clean `price_per_unit`
ppu_update1 <- function(cafe_data) {
  cafe_data %>% 
    mutate(price_per_unit = case_when(
      is.na(price_per_unit) ~ total_spent / Quantity,
      TRUE ~ price_per_unit))
}

ppu_update2 <- function(cafe_data) {
  cafe_data %>% 
    mutate(price_per_unit = case_when(
      is.na(price_per_unit) & Item == "Coffee" ~ 2.0,
      is.na(price_per_unit) & Item == "Tea" ~ 1.5,
      is.na(price_per_unit) & Item == "Sandwich" ~ 4.0,
      is.na(price_per_unit) & Item == "Salad" ~ 5.0,
      is.na(price_per_unit) & Item == "Cake" ~ 3.0,
      is.na(price_per_unit) & Item == "Cookie" ~ 1.0,
      is.na(price_per_unit) & Item == "Smoothie" ~ 4.0,
      is.na(price_per_unit) & Item == "Juice" ~ 3.0,
      TRUE ~ price_per_unit))
}


# 5. Clean `total_spent` (Calculate from Quantity & Price Per Unit)
totspent_update <- function(cafe_data) {
  cafe_data %>% 
    mutate(total_spent = case_when(
      is.na(total_spent) ~ Quantity * price_per_unit,
      TRUE ~ total_spent))
}


###########################################
# Apply Cleaning Functions
###########################################

cafe_data_cleaned <- cafe_data %>% 
  totspent_update() %>% 
  ppu_update2() %>% 
  ppu_update1() %>% 
  quant_update() %>% 
  item_update()

# Reapply to fill additional missing values
cafe_data_cleaned <- cafe_data_cleaned %>% 
  ppu_update2() %>% 
  quant_update() %>% 
  totspent_update()


###########################################
# Handle Categorical Columns
###########################################

# Fill Missing `payment_method` with 'Unknown'
cafe_data_cleaned <- cafe_data_cleaned %>% 
  mutate(payment_method = replace_na(payment_method, "Unknown"))

# Fill Missing `Location` with 'Unknown'
cafe_data_cleaned <- cafe_data_cleaned %>% 
  mutate(Location = replace_na(Location, "Unknown"))

# Leave `transaction_date`NAs as-is (Only 5% Missing)


###########################################
# Missing Data Summary for Cleaned Data
###########################################

# Calculate % Missing per Column
missing_proportion_cleaned <- cafe_data_cleaned %>%
  summarise(across(everything(), ~ mean(is.na(.)) * 100))
print(missing_proportion_cleaned)

# Calculate Overall % Missing
overall_missing_proportion_cleaned <- mean(is.na(cafe_data_cleaned)) * 100
print(overall_missing_proportion_cleaned)  # ~1.3% Missing Data


# Save Cleaned Cafe Data in Directory as Excel Workbook
write.xlsx(cafe_data_cleaned, "R/2025_03_01_Data_Cleaning_ProjectR/cafe_sales_cleaned.xlsx")
