import json
from racket import Racket

class RacketDatabase:
    def __init__(self):
        self.rackets = []

    def add_racket(self, racket_object):
        self.rackets.append(racket_object)

    def find_racket(self, search_term):
        """
        Finds rackets by prioritizing an exact match before falling back to a partial match.
        """
        search_term_lower = search_term.lower()

        # --- First Pass: Look for a single, exact match ---
        exact_matches = []
        for racket in self.rackets:
            full_name = f"{racket.name} {racket.type}".lower()
            if search_term_lower == full_name:
                exact_matches.append(racket)
        
        if len(exact_matches) == 1:
            return exact_matches[0] # Return the single perfect match immediately

        # --- Second Pass: If no single exact match, look for partial matches ---
        partial_matches = []
        for racket in self.rackets:
            full_name = f"{racket.name} {racket.type}".lower()
            if search_term_lower in full_name:
                partial_matches.append(racket)

        # Return the result based on the partial search
        if len(partial_matches) == 0:
            return None
        elif len(partial_matches) == 1:
            return partial_matches[0]
        else: # Ambiguous partial match
            return partial_matches
        
    def save_to_json(self, filename):
        try:
            with open(filename, 'w') as f:
                # Convert list of Racket objects to list of dictionaries
                json.dump([racket.to_dict() for racket in self.rackets], f, indent=4)
            print(f"\nDatabase successfully saved to {filename}")
        except Exception as e:
            print(f"Error saving database: {e}")

    # Method to load the database from a JSON file on startup
    def load_from_json(self, filename):
        try:
            with open(filename, 'r') as f:
                rackets_data = json.load(f)
                self.rackets = [Racket(**data) for data in rackets_data]
            print(f"Database successfully loaded from {filename}")
        except FileNotFoundError:
            print("No existing database file found. Starting fresh.")
        except Exception as e:
            print(f"Error loading database: {e}")