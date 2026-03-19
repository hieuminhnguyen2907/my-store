const String API_BASE_URL = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.100:5000/api',
);

// Endpoints
const String PRODUCTS_ENDPOINT = '$API_BASE_URL/products';
const String CATEGORIES_ENDPOINT = '$API_BASE_URL/categories';
const String FEATURED_PRODUCTS_ENDPOINT = '$API_BASE_URL/products/featured';
