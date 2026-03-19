import {
  App as AntdApp,
  Button,
  Card,
  Col,
  Form,
  Input,
  InputNumber,
  Modal,
  Popconfirm,
  Row,
  Select,
  Space,
  Spin,
  Switch,
  Table,
  Tabs,
  Typography,
} from "antd";
import { useEffect, useMemo, useState } from "react";
import { categoryService } from "./services/category.service";
import { productService } from "./services/product.service";

const categoryColumns = (onEdit, onDelete) => [
  {
    title: "Name",
    dataIndex: "name",
    key: "name",
  },
  {
    title: "Description",
    dataIndex: "description",
    key: "description",
    render: (value) => value || "-",
  },
  {
    title: "Active",
    dataIndex: "isActive",
    key: "isActive",
    render: (value) => (value ? "Yes" : "No"),
  },
  {
    title: "Actions",
    key: "actions",
    render: (_, record) => (
      <Space>
        <Button onClick={() => onEdit(record)}>Edit</Button>
        <Popconfirm
          title="Delete this category?"
          okText="Delete"
          okButtonProps={{ danger: true }}
          onConfirm={() => onDelete(record._id)}
        >
          <Button danger>Delete</Button>
        </Popconfirm>
      </Space>
    ),
  },
];

const productColumns = (onEdit, onDelete) => [
  {
    title: "Name",
    dataIndex: "name",
    key: "name",
  },
  {
    title: "Price",
    dataIndex: "price",
    key: "price",
    render: (value) => `$${Number(value || 0).toFixed(2)}`,
  },
  {
    title: "Stock",
    dataIndex: "stock",
    key: "stock",
  },
  {
    title: "Category",
    dataIndex: "category",
    key: "category",
    render: (category) => category?.name || "-",
  },
  {
    title: "Active",
    dataIndex: "isActive",
    key: "isActive",
    render: (value) => (value ? "Yes" : "No"),
  },
  {
    title: "Actions",
    key: "actions",
    render: (_, record) => (
      <Space>
        <Button onClick={() => onEdit(record)}>Edit</Button>
        <Popconfirm
          title="Delete this product?"
          okText="Delete"
          okButtonProps={{ danger: true }}
          onConfirm={() => onDelete(record._id)}
        >
          <Button danger>Delete</Button>
        </Popconfirm>
      </Space>
    ),
  },
];

function App() {
  const { message } = AntdApp.useApp();
  const [loading, setLoading] = useState(true);

  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);

  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [isProductModalOpen, setIsProductModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [editingProduct, setEditingProduct] = useState(null);

  const [categoryForm] = Form.useForm();
  const [productForm] = Form.useForm();

  const categoryOptions = useMemo(
    () =>
      categories.map((category) => ({
        label: category.name,
        value: category._id,
      })),
    [categories]
  );

  const loadData = async () => {
    setLoading(true);
    try {
      const [categoryResponse, productResponse] = await Promise.all([
        categoryService.getAll(),
        productService.getAll(),
      ]);
      setCategories(categoryResponse.data || []);
      setProducts(productResponse.data || []);
    } catch (error) {
      message.error(error.response?.data?.message || "Failed to load data");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const openCreateCategoryModal = () => {
    setEditingCategory(null);
    categoryForm.resetFields();
    categoryForm.setFieldsValue({ isActive: true });
    setIsCategoryModalOpen(true);
  };

  const openEditCategoryModal = (category) => {
    setEditingCategory(category);
    categoryForm.setFieldsValue({
      name: category.name,
      description: category.description,
      image: category.image,
      isActive: category.isActive,
    });
    setIsCategoryModalOpen(true);
  };

  const submitCategory = async () => {
    const values = await categoryForm.validateFields();

    try {
      if (editingCategory) {
        await categoryService.update(editingCategory._id, values);
        message.success("Category updated");
      } else {
        await categoryService.create(values);
        message.success("Category created");
      }
      setIsCategoryModalOpen(false);
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Failed to save category");
    }
  };

  const deleteCategory = async (id) => {
    try {
      await categoryService.delete(id);
      message.success("Category deleted");
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Failed to delete category");
    }
  };

  const openCreateProductModal = () => {
    setEditingProduct(null);
    productForm.resetFields();
    productForm.setFieldsValue({ isActive: true, stock: 0, price: 0 });
    setIsProductModalOpen(true);
  };

  const openEditProductModal = (product) => {
    setEditingProduct(product);
    productForm.setFieldsValue({
      name: product.name,
      description: product.description,
      price: product.price,
      stock: product.stock,
      unit: product.unit,
      image: product.image,
      isActive: product.isActive,
      category: product.category?._id || product.category,
    });
    setIsProductModalOpen(true);
  };

  const submitProduct = async () => {
    const values = await productForm.validateFields();

    try {
      if (editingProduct) {
        await productService.update(editingProduct._id, values);
        message.success("Product updated");
      } else {
        await productService.create(values);
        message.success("Product created");
      }
      setIsProductModalOpen(false);
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Failed to save product");
    }
  };

  const deleteProduct = async (id) => {
    try {
      await productService.delete(id);
      message.success("Product deleted");
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Failed to delete product");
    }
  };

  if (loading) {
    return (
      <div style={{ height: "100vh", display: "grid", placeItems: "center" }}>
        <Spin size="large" />
      </div>
    );
  }

  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: "0 auto" }}>
      <Typography.Title level={2} style={{ marginTop: 0 }}>
        Big Cart Admin
      </Typography.Title>

      <Tabs
        defaultActiveKey="categories"
        items={[
          {
            key: "categories",
            label: "Categories",
            children: (
              <Card
                title="Manage Categories"
                extra={
                  <Button type="primary" onClick={openCreateCategoryModal}>
                    Add Category
                  </Button>
                }
              >
                <Table
                  rowKey="_id"
                  columns={categoryColumns(openEditCategoryModal, deleteCategory)}
                  dataSource={categories}
                  pagination={{ pageSize: 8 }}
                />
              </Card>
            ),
          },
          {
            key: "products",
            label: "Products",
            children: (
              <Card
                title="Manage Products"
                extra={
                  <Button
                    type="primary"
                    onClick={openCreateProductModal}
                    disabled={categories.length === 0}
                  >
                    Add Product
                  </Button>
                }
              >
                {categories.length === 0 ? (
                  <Typography.Text type="secondary">
                    Please create at least one category before adding products.
                  </Typography.Text>
                ) : null}

                <Table
                  rowKey="_id"
                  columns={productColumns(openEditProductModal, deleteProduct)}
                  dataSource={products}
                  pagination={{ pageSize: 8 }}
                />
              </Card>
            ),
          },
        ]}
      />

      <Modal
        open={isCategoryModalOpen}
        title={editingCategory ? "Edit Category" : "Create Category"}
        onCancel={() => setIsCategoryModalOpen(false)}
        onOk={submitCategory}
        okText={editingCategory ? "Update" : "Create"}
      >
        <Form form={categoryForm} layout="vertical">
          <Form.Item
            label="Name"
            name="name"
            rules={[{ required: true, message: "Please enter category name" }]}
          >
            <Input placeholder="Category name" />
          </Form.Item>
          <Form.Item label="Description" name="description">
            <Input.TextArea rows={3} placeholder="Description" />
          </Form.Item>
          <Form.Item label="Image URL" name="image">
            <Input placeholder="https://..." />
          </Form.Item>
          <Form.Item label="Active" name="isActive" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        open={isProductModalOpen}
        title={editingProduct ? "Edit Product" : "Create Product"}
        onCancel={() => setIsProductModalOpen(false)}
        onOk={submitProduct}
        okText={editingProduct ? "Update" : "Create"}
        width={720}
      >
        <Form form={productForm} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label="Name"
                name="name"
                rules={[{ required: true, message: "Please enter product name" }]}
              >
                <Input placeholder="Product name" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label="Category"
                name="category"
                rules={[{ required: true, message: "Please select category" }]}
              >
                <Select placeholder="Select category" options={categoryOptions} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Description" name="description">
            <Input.TextArea rows={3} placeholder="Description" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item
                label="Price"
                name="price"
                rules={[{ required: true, message: "Please enter price" }]}
              >
                <InputNumber min={0} style={{ width: "100%" }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Stock" name="stock">
                <InputNumber min={0} style={{ width: "100%" }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Unit" name="unit">
                <Select
                  options={[
                    { value: "kg", label: "kg" },
                    { value: "gram", label: "gram" },
                    { value: "piece", label: "piece" },
                  ]}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Image URL" name="image">
            <Input placeholder="https://..." />
          </Form.Item>

          <Form.Item label="Active" name="isActive" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}

export default App;
