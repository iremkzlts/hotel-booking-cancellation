# Hotel Booking Cancellation Prediction and Analysis System

**A Data Analytics and Machine Learning Project**

---

## About the Project

This project aims to analyze hotel booking data and predict the likelihood of reservation cancellations.

By combining hotel booking records with historical weather information and airport flight delay data, the project investigates factors that may influence booking cancellations.

The main goal is to help hotel businesses make better decisions about room planning, reservation management, and operational efficiency.

## Data Sources

- **Hotel Booking Data:** Reservation details, customer information, booking channels, and cancellation records.
- **Open-Meteo:** Historical weather data associated with hotel locations and arrival dates.
- **EUROCONTROL:** Airport traffic and flight delay information covering 2015–2017.

## Project Objectives

- Analyze hotel booking and cancellation patterns.
- Identify factors associated with booking cancellations.
- Integrate weather and flight delay data.
- Clean and transform datasets.
- Develop a machine learning model to predict cancellation risk.
- Present findings through visualizations and dashboards.

## Project Structure

```text
hotel-booking-cancellation/
├── data/
│   ├── raw/
│   │   ├── hotel_booking/
│   │   ├── eurocontrol/
│   │   └── open_meteo/
│   └── processed/
│       ├── hotel_booking/
│       ├── eurocontrol/
│       └── open_meteo/
├── process/
│   ├── eurocontrol_data_cleaning.ipynb
│   ├── hotel_booking_cleaning.ipynb
│   └── open_meteo_data_cleaning.ipynb
└── README.md
```

## Project Workflow

1. **Data Collection**
2. **Data Cleaning and ETL**
3. **Data Analysis and Visualization**
4. **Machine Learning Model Development**
5. **Model Deployment**

## Technologies

- Python
- Google Colab
- SQL
- dbt
- Pandas
- Scikit-learn
- GitHub

## Project Status

The project is currently in the data preparation and processing stage. Data analysis, dashboard development, machine learning model training, and deployment will follow.

## Team Collaboration

This repository is used to organize project files, document data processing workflows, track changes, and support collaboration among team members.
