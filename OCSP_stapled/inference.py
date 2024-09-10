import os
import re
from datetime import datetime
import pandas as pd

base_directory = '/home/nsl404/Desktop/OCSP/ocsp_responses'
data = []
file_pattern = re.compile(r'stapled_ocsp_response_(\d{8})_(\d{6})\.txt')

def extract_produced_at(file_path):
    with open(file_path, 'r') as f:
        for line in f:
            if "Produced At" in line:
                produced_at_str = line.split(": ", 1)[1].strip()
                produced_at = datetime.strptime(produced_at_str, '%b %d %H:%M:%S %Y %Z')
                return produced_at
    return None

for domain in os.listdir(base_directory):
    domain_path = os.path.join(base_directory, domain)
    if os.path.isdir(domain_path):
        for filename in os.listdir(domain_path):
            match = file_pattern.match(filename)
            if match:
                file_date_str = match.group(1)
                file_time_str = match.group(2)
                try:
                    file_timestamp_str = file_date_str + file_time_str
                    file_timestamp = datetime.strptime(file_timestamp_str, '%Y%m%d%H%M%S')
                except ValueError as e:
                    print(f"Error parsing filename timestamp: {e}")
                    continue
                file_path = os.path.join(domain_path, filename)
                produced_at = extract_produced_at(file_path)
                if produced_at:
                    data.append({
                        'Domain': domain,
                        'Filename Timestamp': file_timestamp,
                        'Produced At': produced_at
                    })

df = pd.DataFrame(data)
df = df.sort_values(by=['Domain', 'Filename Timestamp'])
print(df)
df.to_csv('/home/nsl404/Desktop/OCSP/ocsp_responses_timestamps.csv', index=False)
