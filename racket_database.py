class RacketDatabase:
    def __init__(self):
        self.rackets = []

    def add_racket(self, racket_object):
        self.rackets.append(racket_object)

    def find_racket(self, racket_object_type):
        for index, racket in enumerate(self.rackets):
            if racket.name == racket_object_type:
                print(f"The racket '{racket_object_type}' is at index {index}")
                return # Stop after finding the first match
        print(f"The racket '{racket_object_type}' was not found in the database.")
        # need to add additional search for type of racket in addition to name