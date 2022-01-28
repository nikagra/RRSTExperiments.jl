import json, requests, time, csv

def flat_map(f, xs):
    ys = []
    for x in xs:
        ys.extend(f(x))
    return ys

def get_duration(from_a, to_b):
    url = "https://www.ryanair.com/api/booking/v4/en-ie/availability"
    params = {"ADT": "1", "CHD": "0", "DateIn": "2022-04-09", "DateOut": "2022-04-02", "Destination": to_b, "Disc": "0", "INF": "0", "Origin": from_a, "TEEN": "0", "promoCode": "", "IncludeConnectingFlights": "false", "FlexDaysBeforeIn": "2", "FlexDaysIn": "2", "RoundTrip": "true", "FlexDaysBeforeOut": "2", "FlexDaysOut": "2", "ToUs": "AGREED"}
    r = requests.get(url = url, params = params)
    if r.status_code == 200:
        trips = r.json()['trips']
        dates = flat_map(lambda x: x['dates'], trips)
        flights = flat_map(lambda x: x['flights'], dates)
        durations = list(map(lambda x: x['duration'], flights))
        time.sleep(0.25)
        return "" if len(durations) == 0 else durations[0]
    else:
        return ""


def initial_import():
    file = open(r".\res\ryanair-routes.json")
    routes_unfiltered = json.load(file)
    edges = dict()
    fields = ['Origin', 'Destination', 'Duration']
    with open(r".\res\ryanair.csv", 'w') as f:
        write = csv.writer(f)
        write.writerow(fields)
        for from_a in routes_unfiltered:
            for to_b in routes_unfiltered[from_a]:
                if not ((from_a, to_b) in edges or (to_b, from_a) in edges):
                    edges[(from_a, to_b)] = get_duration(from_a, to_b)
                    write.writerow([from_a, to_b, edges[(from_a, to_b)]])

def data_complementing():
    edges = dict()
    fields = ['Origin', 'Destination', 'Duration']
    with open(r".\res\ryanair.csv", 'r') as f:
        routes = csv.DictReader(f)
        for route in routes:
            from_a = route['Origin']
            to_b = route['Destination']
            if not ((from_a, to_b) in edges or (to_b, from_a) in edges):
                duration_splited = route['Duration'].split(':')
                duration_final = 60 * int(duration_splited[0]) + int(duration_splited[1])
                edges[(from_a, to_b)] = duration_final

    with open(r".\res\ryanair.csv", 'w') as f:
        write = csv.writer(f)
        write.writerow(fields)
        for (from_a, to_b) in edges:
            if edges[(from_a, to_b)] == 0:
                edges[(from_a, to_b)] = get_duration(from_a, to_b)
            write.writerow([from_a, to_b, edges[(from_a, to_b)]])

data_complementing()