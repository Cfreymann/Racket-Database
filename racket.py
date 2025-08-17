class Racket:
    def __init__(self, brand, name, type, weight, head_size, stiffness, string_pattern):
        self.brand = brand
        self.name = name
        self.type = type
        self.weight = weight
        self.head_size = head_size
        self.stiffness = stiffness
        self.string_pattern = string_pattern
        self.status = "Current"
    
    def mark_as_old(self):
        self.status = "Outdated"

    def show_details(self):
        print(f"Brand: {self.brand}")
        print(f"Name: {self.name}")
        print(f"Type: {self.type}")
        print(f"Weight: {self.weight}")
        print(f"Head Size: {self.head_size}")
        print(f"Stiffness: {self.stiffness}")
        print(f"Status: {self.status}")
    