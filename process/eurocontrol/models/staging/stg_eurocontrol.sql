SELECT *
FROM read_csv_auto(
    '../../data/processed/eurocontrol/eurocontrol_combined.csv',
    header = true
)