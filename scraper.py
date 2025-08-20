import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, quote_plus
import time

# NEW imports for Selenium
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def find_product_url(brand: str, name: str, type_model: str, site_code: str, debug=False) -> str | None:
    """
    Finds a product URL. Uses requests for simple sites and Selenium for JS-heavy sites.
    """
    # This path assumes 'chromedriver.exe' is in the same folder as your script.
    CHROME_DRIVER_PATH = r'C:\Coding Projects\Practice Python\Racket Database\chromedriver.exe'

    SITES = {
        'TE': {
            'base_url': "https://www.tennisexpress.com",
            'search_path': "/search?q=",
            'link_selector': 'a.product-card-title'
        },
        'TW': {
            'base_url': "https://www.tennis-warehouse.com",
            'search_path': "/search-tennis.html?searchtext=",
            'link_selector': 'a.cattable-wrap-cell-info' # The correct selector you found
        }
    }

    config = SITES.get(site_code)
    if not config:
        print(f"Unknown site code: {site_code}")
        return None

    base_url, search_path, link_selector = config.values()
    full_search_name = f"{brand} {name} {type_model}"
    search_url = f"{base_url}{search_path}{quote_plus(full_search_name)}"
    
    print(f"-> Searching for '{full_search_name}' on {site_code}...")
    
    page_html = None

    # --- Use Selenium ONLY for Tennis Warehouse ---
    if site_code == 'TW':
        try:
            service = Service(executable_path=CHROME_DRIVER_PATH)
            options = webdriver.ChromeOptions()
            # This line makes the browser run in the background without a visible window.
            # You can comment it out if you want to see the browser open.
            options.add_argument('--headless') 
            options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
            
            driver = webdriver.Chrome(service=service, options=options)
            driver.get(search_url)

            # --- CRUCIAL: Wait up to 10 seconds for the product links to appear ---
            print("   (Waiting for JavaScript to load page content...)")
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, link_selector))
            )
            
            # Now that the page is loaded, get the final HTML
            page_html = driver.page_source
            driver.quit() # Close the browser
        except Exception as e:
            print(f"An error occurred with Selenium: {e}")
            return None
    
    # --- Use simple requests for Tennis Express ---
    else: 
        try:
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
            response = requests.get(search_url, headers=headers, timeout=20)
            response.raise_for_status()
            page_html = response.text
        except Exception as e:
            print(f"An error occurred with requests: {e}")
            return None

    # --- The rest of the logic to parse the HTML is the same as before ---
    if not page_html:
        return None

    try:
        soup = BeautifulSoup(page_html, 'html.parser')
        
        if debug:
            debug_filename = f"debug_{site_code}.html"
            with open(debug_filename, 'w', encoding='utf-8') as f:
                f.write(soup.prettify())
            print(f"   !!! Saved search results page to '{debug_filename}'")

        all_link_elements = soup.select(link_selector)
        if not all_link_elements:
            print("   ⚠️ No product links found with the current selector.")
            return None

        core_keywords = name.lower().split() + type_model.lower().split()
        racquet_links = []
        other_links = []

        for link in all_link_elements:
            link_text = link.get_text(strip=True).lower()
            if all(keyword in link_text for keyword in core_keywords) and 'junior' not in link_text and 'demo' not in link_text:
                if 'racquet' in link_text or 'racket' in link_text or site_code == 'TW':
                    racquet_links.append(link)
                else:
                    other_links.append(link)
        
        best_match_link = racquet_links[0] if racquet_links else (other_links[0] if other_links else None)

        if best_match_link and best_match_link.has_attr('href'):
            absolute_url = urljoin(base_url, best_match_link['href'])
            print(f"   ✅ Found best match: {absolute_url}")
            return absolute_url

        print(f"   ⚠️ Could not find a specific match for '{full_search_name}'.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing the HTML: {e}")
        return None