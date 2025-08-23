import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, quote_plus
import time

# --- Selenium Imports ---
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# --- Browser-Specific Imports for Firefox ---
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options as FirefoxOptions


def find_product_url(brand: str, name: str, type_model: str, site_code: str, debug=False) -> str | None:
    """
    Finds a product URL. Uses requests for simple sites and Selenium for JS-heavy sites.
    """
    SITES = {
        'TE': {
            'base_url': "https://www.tennisexpress.com",
            'search_path': "/search?q=",
            'link_selector': 'a.product-card-title'
        },
        'TW': {
            'base_url': "https://www.tennis-warehouse.com",
            'search_path': "/search-tennis.html?searchtext=",
            'link_selector': 'a.cattable-wrap-cell-info'
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

    # --- Use Selenium with Firefox for Tennis Warehouse ---
    if site_code == 'TW':
        try:
            FIREFOX_DRIVER_PATH = r'C:\Coding Projects\Practice Python\Racket Database\geckodriver.exe' # UPDATE THIS PATH
            
            # Use the Firefox-specific imports to set up the driver
            service = FirefoxService(executable_path=FIREFOX_DRIVER_PATH, log_output=os.devnull)
            options = FirefoxOptions()
            options.add_argument('--headless')
            
            driver = webdriver.Firefox(service=service, options=options)
            
            driver.get(search_url)

            print("   (Waiting for page to load...)")
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, link_selector))
            )
            
            page_html = driver.page_source
            driver.quit()
        except Exception as e:
            print(f"   ❌ Unable to connect to Tennis Warehouse. Please check your internet connection.")
            return None
    
    # --- Use simple requests for Tennis Express ---
    else: 
        try:
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
            response = requests.get(search_url, headers=headers, timeout=20)
            response.raise_for_status()
            page_html = response.text
        except Exception as e:
            print("   ❌ Unable to connect to Tennis Express. Please check your internet connection.")
            return None

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


def fetch_prices_from_url(product_url: str) -> dict:
    """
    Scrapes the sale and original price from a given product URL.
    Returns a dictionary with 'sale_price' and 'original_price'.
    """
    if not product_url:
        return {}

    SITE_CONFIG = {
        'TE': {
            'sale_price_selector': 'span.discounted',
            'original_price_selector': 'del span.amount' 
        },
        'TW': {
            'sale_price_selector': 'div.price',
            'original_price_selector': 'del'
        }
    }

    site_code = None
    if 'tennisexpress.com' in product_url:
        site_code = 'TE'
    elif 'tennis-warehouse.com' in product_url:
        site_code = 'TW'
    
    if not site_code:
        print(f"   ⚠️ URL not recognized: {product_url}")
        return {}

    config = SITE_CONFIG[site_code]
    prices = {'sale_price': None, 'original_price': None}

    try:
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        response = requests.get(product_url, headers=headers, timeout=20)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        def clean_price(price_text):
            if not price_text: return None
            cleaned_text = price_text.strip().replace('$', '').replace(',', '')
            try:
                return float(cleaned_text)
            except (ValueError, TypeError):
                return None

        sale_price_element = soup.select_one(config['sale_price_selector'])
        if sale_price_element:
            prices['sale_price'] = clean_price(sale_price_element.get_text())
            print(f"   ✅ Found Sale Price: ${prices['sale_price']:.2f}")
        else:
            print(f"   ⚠️ Sale price not found with selector: {config['sale_price_selector']}")

        original_price_element = soup.select_one(config['original_price_selector'])
        if original_price_element:
            prices['original_price'] = clean_price(original_price_element.get_text())
            print(f"   ✅ Found Original Price: ${prices['original_price']:.2f}")
        
        if prices['sale_price'] and not prices['original_price']:
            prices['original_price'] = prices['sale_price']

    except Exception as e:
        site_name = "Tennis Express" if site_code == 'TE' else "Tennis Warehouse"
        print(f"   ❌ Error fetching prices from {site_name}. Please check your connection.")

    return prices