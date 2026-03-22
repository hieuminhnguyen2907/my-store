const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.103:5000/api',
);

// Endpoints
const String productsEndpoint = '$apiBaseUrl/products';
const String categoriesEndpoint = '$apiBaseUrl/categories';
const String featuredProductsEndpoint = '$apiBaseUrl/products/featured';
const String momoCreatePaymentEndpoint = '$apiBaseUrl/payments/momo/create';
const String momoStatusEndpoint = '$apiBaseUrl/payments/momo/status';
