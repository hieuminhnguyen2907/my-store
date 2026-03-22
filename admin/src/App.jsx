import {
  AutoComplete,
  App as AntdApp,
  Alert,
  Button,
  Card,
  Col,
  Descriptions,
  Form,
  Layout,
  Input,
  InputNumber,
  Menu,
  Modal,
  Popconfirm,
  Row,
  Select,
  Space,
  Spin,
  Statistic,
  Switch,
  Tag,
  Table,
  Tooltip,
  Typography,
  Upload,
} from "antd";
import { useCallback, useEffect, useMemo, useState } from "react";
import "./App.css";
import { categoryService } from "./services/category.service";
import { productService } from "./services/product.service";
import { userService } from "./services/user.service";

const { Sider, Content } = Layout;

const toOptions = (items = []) =>
  Array.from(new Set(items.filter(Boolean))).map((item) => ({
    value: item,
    label: item,
  }));

const readFileAsDataUrl = (file) =>
  new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(new Error("Không thể đọc file ảnh"));
    reader.readAsDataURL(file);
  });

const formatVnd = (value) =>
  new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(Number(value || 0));

const categoryColumns = (onEdit, onDelete) => [
  {
    title: "Tên danh mục",
    dataIndex: "name",
    key: "name",
  },
  {
    title: "Mô tả",
    dataIndex: "description",
    key: "description",
    render: (value) => value || "-",
  },
  {
    title: "Trạng thái",
    dataIndex: "isActive",
    key: "isActive",
    render: (value) =>
      value ? <Tag color="green">Đang hoạt động</Tag> : <Tag>Tạm ẩn</Tag>,
  },
  {
    title: "Thao tác",
    key: "actions",
    render: (_, record) => (
      <Space>
        <Button onClick={() => onEdit(record)}>Sửa</Button>
        <Popconfirm
          title="Xóa danh mục này?"
          okText="Xóa"
          cancelText="Hủy"
          okButtonProps={{ danger: true }}
          onConfirm={() => onDelete(record._id)}
        >
          <Button danger>Xóa</Button>
        </Popconfirm>
      </Space>
    ),
  },
];

const productColumns = (onEdit, onDelete) => [
  {
    title: "Tên sản phẩm",
    dataIndex: "name",
    key: "name",
  },
  {
    title: "Giá",
    dataIndex: "price",
    key: "price",
    render: (value) => formatVnd(value),
  },
  {
    title: "Tồn kho",
    dataIndex: "stock",
    key: "stock",
    render: (value) => {
      const stock = Number(value || 0);
      if (stock === 0) return <Tag color="red">Hết hàng</Tag>;
      if (stock < 10) return <Tag color="orange">Sắp hết ({stock})</Tag>;
      return <Tag color="green">{stock}</Tag>;
    },
  },
  {
    title: "Danh mục",
    dataIndex: "category",
    key: "category",
    render: (category) => category?.name || "-",
  },
  {
    title: "Trạng thái",
    dataIndex: "isActive",
    key: "isActive",
    render: (value) =>
      value ? <Tag color="green">Đang bán</Tag> : <Tag>Tạm ẩn</Tag>,
  },
  {
    title: "Thao tác",
    key: "actions",
    render: (_, record) => (
      <Space>
        <Button onClick={() => onEdit(record)}>Sửa</Button>
        <Popconfirm
          title="Xóa sản phẩm này?"
          okText="Xóa"
          cancelText="Hủy"
          okButtonProps={{ danger: true }}
          onConfirm={() => onDelete(record._id)}
        >
          <Button danger>Xóa</Button>
        </Popconfirm>
      </Space>
    ),
  },
];

function App() {
  const { message } = AntdApp.useApp();

  const [activeMenu, setActiveMenu] = useState("dashboard");
  const [loading, setLoading] = useState(true);
  const [errorText, setErrorText] = useState("");

  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [users, setUsers] = useState([]);

  const [categoryKeyword, setCategoryKeyword] = useState("");
  const [categoryStatus, setCategoryStatus] = useState("all");
  const [productKeyword, setProductKeyword] = useState("");
  const [productStatus, setProductStatus] = useState("all");
  const [productCategory, setProductCategory] = useState("all");
  const [userKeyword, setUserKeyword] = useState("");
  const [userRoleFilter, setUserRoleFilter] = useState("all");
  const [categoryImagePreview, setCategoryImagePreview] = useState("");
  const [productImagePreview, setProductImagePreview] = useState("");

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

  const categoryNameSuggestions = useMemo(
    () => toOptions(categories.map((item) => item.name)),
    [categories]
  );

  const productNameSuggestions = useMemo(
    () => toOptions(products.map((item) => item.name)),
    [products]
  );

  const unitSuggestions = useMemo(
    () =>
      toOptions([
        "kg",
        "gram",
        "piece",
        "box",
        "set",
        "bottle",
        ...products.map((item) => item.unit),
      ]),
    [products]
  );

  const dashboardStats = useMemo(() => {
    const activeCategoryCount = categories.filter((item) => item.isActive).length;
    const activeProductCount = products.filter((item) => item.isActive).length;
    const outOfStockCount = products.filter((item) => Number(item.stock || 0) <= 0).length;
    const lowStockCount = products.filter((item) => {
      const stock = Number(item.stock || 0);
      return stock > 0 && stock < 10;
    }).length;

    return {
      activeCategoryCount,
      activeProductCount,
      outOfStockCount,
      lowStockCount,
      userCount: users.length,
    };
  }, [categories, products, users]);

  const filteredCategories = useMemo(() => {
    return categories.filter((item) => {
      const keyword = categoryKeyword.trim().toLowerCase();
      const hitKeyword =
        !keyword ||
        item.name?.toLowerCase().includes(keyword) ||
        item.description?.toLowerCase().includes(keyword);
      const hitStatus =
        categoryStatus === "all" ||
        (categoryStatus === "active" ? item.isActive : !item.isActive);
      return hitKeyword && hitStatus;
    });
  }, [categories, categoryKeyword, categoryStatus]);

  const filteredProducts = useMemo(() => {
    return products.filter((item) => {
      const keyword = productKeyword.trim().toLowerCase();
      const hitKeyword =
        !keyword ||
        item.name?.toLowerCase().includes(keyword) ||
        item.description?.toLowerCase().includes(keyword);
      const hitStatus =
        productStatus === "all" ||
        (productStatus === "active" ? item.isActive : !item.isActive);
      const productCategoryId = item.category?._id || item.category;
      const hitCategory =
        productCategory === "all" || productCategoryId === productCategory;
      return hitKeyword && hitStatus && hitCategory;
    });
  }, [products, productKeyword, productStatus, productCategory]);

  const filteredUsers = useMemo(() => {
    return users.filter((item) => {
      const keyword = userKeyword.trim().toLowerCase();
      const hitKeyword =
        !keyword ||
        item.name?.toLowerCase().includes(keyword) ||
        item.email?.toLowerCase().includes(keyword) ||
        item.phone?.toLowerCase().includes(keyword);
      const hitRole = userRoleFilter === "all" || item.role === userRoleFilter;
      return hitKeyword && hitRole;
    });
  }, [users, userKeyword, userRoleFilter]);

  const userColumns = [
    {
      title: "Họ tên",
      dataIndex: "name",
      key: "name",
    },
    {
      title: "Email",
      dataIndex: "email",
      key: "email",
    },
    {
      title: "Số điện thoại",
      dataIndex: "phone",
      key: "phone",
      render: (value) => value || "-",
    },
    {
      title: "Vai trò",
      dataIndex: "role",
      key: "role",
      render: (value) =>
        value === "admin" ? <Tag color="gold">Admin</Tag> : <Tag>User</Tag>,
    },
    {
      title: "Ngày tạo",
      dataIndex: "createdAt",
      key: "createdAt",
      render: (value) => (value ? new Date(value).toLocaleString("vi-VN") : "-"),
    },
  ];

  const categoryColumnsConfig = categoryColumns(
    (item) => openEditCategoryModal(item),
    (id) => deleteCategory(id)
  );

  const productColumnsConfig = productColumns(
    (item) => openEditProductModal(item),
    (id) => deleteProduct(id)
  );

  const loadData = useCallback(async () => {
    setLoading(true);
    setErrorText("");

    try {
      const [categoryResponse, productResponse, userResponse] = await Promise.all([
        categoryService.getAll(),
        productService.getAll(),
        userService.getAll().catch(() => ({ data: [] })),
      ]);

      setCategories(categoryResponse.data || []);
      setProducts(productResponse.data || []);
      setUsers(userResponse.data || []);
    } catch (error) {
      const text = error.response?.data?.message || "Không thể tải dữ liệu";
      setErrorText(text);
      message.error(text);
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const openCreateCategoryModal = () => {
    setEditingCategory(null);
    categoryForm.resetFields();
    categoryForm.setFieldsValue({ isActive: true });
    setCategoryImagePreview("");
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
    setCategoryImagePreview(category.image || "");
    setIsCategoryModalOpen(true);
  };

  const submitCategory = async () => {
    const values = await categoryForm.validateFields();

    try {
      if (editingCategory) {
        await categoryService.update(editingCategory._id, values);
        message.success("Cập nhật danh mục thành công");
      } else {
        await categoryService.create(values);
        message.success("Tạo danh mục thành công");
      }
      setIsCategoryModalOpen(false);
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Không thể lưu danh mục");
    }
  };

  const deleteCategory = async (id) => {
    try {
      await categoryService.delete(id);
      message.success("Xóa danh mục thành công");
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Không thể xóa danh mục");
    }
  };

  const openCreateProductModal = () => {
    setEditingProduct(null);
    productForm.resetFields();
    productForm.setFieldsValue({ isActive: true, stock: 0, price: 0 });
    setProductImagePreview("");
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
    setProductImagePreview(product.image || "");
    setIsProductModalOpen(true);
  };

  const submitProduct = async () => {
    const values = await productForm.validateFields();

    try {
      if (editingProduct) {
        await productService.update(editingProduct._id, values);
        message.success("Cập nhật sản phẩm thành công");
      } else {
        await productService.create(values);
        message.success("Tạo sản phẩm thành công");
      }
      setIsProductModalOpen(false);
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Không thể lưu sản phẩm");
    }
  };

  const deleteProduct = async (id) => {
    try {
      await productService.delete(id);
      message.success("Xóa sản phẩm thành công");
      await loadData();
    } catch (error) {
      message.error(error.response?.data?.message || "Không thể xóa sản phẩm");
    }
  };

  const uploadImageToField = async (file, form, setPreview) => {
    if (!file?.type?.startsWith("image/")) {
      message.error("Vui lòng chọn đúng định dạng ảnh");
      return false;
    }

    try {
      const dataUrl = await readFileAsDataUrl(file);
      form.setFieldValue("image", dataUrl);
      setPreview(dataUrl);
      message.success("Tải ảnh từ máy lên thành công");
    } catch {
      message.error("Không thể tải ảnh lên");
    }

    return false;
  };

  if (loading) {
    return (
      <div style={{ height: "100vh", display: "grid", placeItems: "center" }}>
        <Spin size="large" />
      </div>
    );
  }

  const renderDashboard = () => (
    <div className="admin-page-stack">
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card className="admin-stat-card">
            <Statistic title="Danh mục hoạt động" value={dashboardStats.activeCategoryCount} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="admin-stat-card">
            <Statistic title="Sản phẩm đang bán" value={dashboardStats.activeProductCount} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="admin-stat-card">
            <Statistic title="Sắp hết hàng" value={dashboardStats.lowStockCount} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="admin-stat-card">
            <Statistic title="Người dùng" value={dashboardStats.userCount} />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={14}>
          <Card title="Tổng quan vận hành" className="admin-panel-card">
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="Sản phẩm hết hàng">
                {dashboardStats.outOfStockCount}
              </Descriptions.Item>
              <Descriptions.Item label="Danh mục tạm ẩn">
                {categories.length - dashboardStats.activeCategoryCount}
              </Descriptions.Item>
              <Descriptions.Item label="Sản phẩm tạm ẩn">
                {products.length - dashboardStats.activeProductCount}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>
        <Col xs={24} lg={10}>
          <Card title="Thao tác nhanh" className="admin-panel-card">
            <Space direction="vertical" style={{ width: "100%" }}>
              <Button type="primary" block onClick={openCreateCategoryModal}>
                Thêm danh mục mới
              </Button>
              <Button
                block
                onClick={openCreateProductModal}
                disabled={categories.length === 0}
              >
                Thêm sản phẩm mới
              </Button>
            </Space>
          </Card>
        </Col>
      </Row>
    </div>
  );

  const renderCategories = () => (
    <Card
      className="admin-panel-card"
      title="Quản lý danh mục"
      extra={
        <Button type="primary" onClick={openCreateCategoryModal}>
          Thêm danh mục
        </Button>
      }
    >
      <Row gutter={[12, 12]} style={{ marginBottom: 12 }}>
        <Col xs={24} md={16}>
          <Input.Search
            allowClear
            placeholder="Tìm theo tên hoặc mô tả danh mục"
            value={categoryKeyword}
            onChange={(event) => setCategoryKeyword(event.target.value)}
          />
        </Col>
        <Col xs={24} md={8}>
          <Select
            style={{ width: "100%" }}
            value={categoryStatus}
            onChange={setCategoryStatus}
            options={[
              { label: "Tất cả trạng thái", value: "all" },
              { label: "Đang hoạt động", value: "active" },
              { label: "Tạm ẩn", value: "inactive" },
            ]}
          />
        </Col>
      </Row>

      <Table
        className="admin-table"
        rowKey="_id"
        columns={categoryColumnsConfig}
        dataSource={filteredCategories}
        pagination={{ pageSize: 8 }}
      />
    </Card>
  );

  const renderProducts = () => (
    <Card
      className="admin-panel-card"
      title="Quản lý sản phẩm"
      extra={
        <Button
          type="primary"
          onClick={openCreateProductModal}
          disabled={categories.length === 0}
        >
          Thêm sản phẩm
        </Button>
      }
    >
      {categories.length === 0 ? (
        <Alert
          type="warning"
          style={{ marginBottom: 12 }}
          message="Bạn cần tạo ít nhất 1 danh mục trước khi thêm sản phẩm."
        />
      ) : null}

      <Row gutter={[12, 12]} style={{ marginBottom: 12 }}>
        <Col xs={24} lg={10}>
          <Input.Search
            allowClear
            placeholder="Tìm theo tên hoặc mô tả sản phẩm"
            value={productKeyword}
            onChange={(event) => setProductKeyword(event.target.value)}
          />
        </Col>
        <Col xs={24} md={12} lg={7}>
          <Select
            style={{ width: "100%" }}
            value={productCategory}
            onChange={setProductCategory}
            options={[
              { label: "Tất cả danh mục", value: "all" },
              ...categoryOptions,
            ]}
          />
        </Col>
        <Col xs={24} md={12} lg={7}>
          <Select
            style={{ width: "100%" }}
            value={productStatus}
            onChange={setProductStatus}
            options={[
              { label: "Tất cả trạng thái", value: "all" },
              { label: "Đang bán", value: "active" },
              { label: "Tạm ẩn", value: "inactive" },
            ]}
          />
        </Col>
      </Row>

      <Table
        className="admin-table"
        rowKey="_id"
        columns={productColumnsConfig}
        dataSource={filteredProducts}
        pagination={{ pageSize: 8 }}
      />
    </Card>
  );

  const renderUsers = () => (
    <Card className="admin-panel-card" title="Quản lý người dùng">
      <Alert
        style={{ marginBottom: 12 }}
        type="info"
        message="Người dùng tự đăng ký tài khoản trong app. Admin chỉ theo dõi danh sách người dùng."
      />

      <Row gutter={[12, 12]} style={{ marginBottom: 12 }}>
        <Col xs={24} md={16}>
          <Input.Search
            allowClear
            placeholder="Tìm theo tên, email, số điện thoại"
            value={userKeyword}
            onChange={(event) => setUserKeyword(event.target.value)}
          />
        </Col>
        <Col xs={24} md={8}>
          <Select
            style={{ width: "100%" }}
            value={userRoleFilter}
            onChange={setUserRoleFilter}
            options={[
              { label: "Tất cả vai trò", value: "all" },
              { label: "Admin", value: "admin" },
              { label: "User", value: "user" },
            ]}
          />
        </Col>
      </Row>

      <Table
        className="admin-table"
        rowKey="id"
        columns={userColumns}
        dataSource={filteredUsers}
        pagination={{ pageSize: 8 }}
      />
    </Card>
  );

  const renderCurrentSection = () => {
    if (activeMenu === "dashboard") return renderDashboard();
    if (activeMenu === "categories") return renderCategories();
    if (activeMenu === "products") return renderProducts();
    return renderUsers();
  };

  return (
    <>
      <Layout className="admin-shell" style={{ minHeight: "100vh" }}>
        <Sider width={250} theme="light" className="admin-sider">
          <div className="admin-brand">Big Cart Admin</div>
          <Menu
            className="admin-menu"
            mode="inline"
            selectedKeys={[activeMenu]}
            onClick={({ key }) => setActiveMenu(key)}
            items={[
              { key: "dashboard", label: "Tổng quan" },
              { key: "categories", label: "Danh mục" },
              { key: "products", label: "Sản phẩm" },
              { key: "users", label: "Người dùng" },
            ]}
          />
        </Sider>

        <Layout className="admin-main-layout">

          <Content className="admin-content">
            {errorText ? (
              <Alert type="error" message={errorText} style={{ marginBottom: 12 }} />
            ) : null}
            {renderCurrentSection()}
          </Content>
        </Layout>
      </Layout>

      <Modal
        open={isCategoryModalOpen}
        title={editingCategory ? "Cập nhật danh mục" : "Tạo danh mục"}
        onCancel={() => setIsCategoryModalOpen(false)}
        onOk={submitCategory}
        okText={editingCategory ? "Cập nhật" : "Tạo mới"}
        cancelText="Hủy"
      >
        <Form form={categoryForm} layout="vertical">
          <Form.Item
            label="Tên danh mục"
            name="name"
            rules={[{ required: true, message: "Vui lòng nhập tên danh mục" }]}
          >
            <AutoComplete
              options={categoryNameSuggestions}
              filterOption={(input, option) =>
                (option?.value || "").toLowerCase().includes(input.toLowerCase())
              }
              placeholder="Chọn nhanh từ gợi ý hoặc nhập mới"
            />
          </Form.Item>
          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} placeholder="Mô tả ngắn cho danh mục" />
          </Form.Item>

          <Form.Item label="Ảnh danh mục" name="image">
            <Input
              placeholder="Dán URL ảnh hoặc dùng nút tải từ máy"
              onChange={(event) => setCategoryImagePreview(event.target.value)}
            />
          </Form.Item>

          <div className="admin-upload-row">
            <Upload
              accept="image/*"
              showUploadList={false}
              beforeUpload={(file) =>
                uploadImageToField(file, categoryForm, setCategoryImagePreview)
              }
            >
              <Button>Tải ảnh từ máy</Button>
            </Upload>
            <Typography.Text type="secondary">
              Hỗ trợ JPG, PNG, WEBP. Ảnh sẽ tự điền vào form.
            </Typography.Text>
          </div>

          {categoryImagePreview ? (
            <div className="admin-image-preview-wrap">
              <img src={categoryImagePreview} alt="Xem trước danh mục" className="admin-image-preview" />
            </div>
          ) : null}

          <Form.Item label="Kích hoạt" name="isActive" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        open={isProductModalOpen}
        title={editingProduct ? "Cập nhật sản phẩm" : "Tạo sản phẩm"}
        onCancel={() => setIsProductModalOpen(false)}
        onOk={submitProduct}
        okText={editingProduct ? "Cập nhật" : "Tạo mới"}
        cancelText="Hủy"
        width={720}
      >
        <Form form={productForm} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label="Tên sản phẩm"
                name="name"
                rules={[{ required: true, message: "Vui lòng nhập tên sản phẩm" }]}
              >
                <AutoComplete
                  options={productNameSuggestions}
                  filterOption={(input, option) =>
                    (option?.value || "").toLowerCase().includes(input.toLowerCase())
                  }
                  placeholder="Chọn nhanh từ gợi ý hoặc nhập mới"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label="Danh mục"
                name="category"
                rules={[{ required: true, message: "Vui lòng chọn danh mục" }]}
              >
                <Select
                  showSearch
                  optionFilterProp="label"
                  placeholder="Chọn danh mục"
                  options={categoryOptions}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} placeholder="Mô tả ngắn về sản phẩm" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item
                label="Giá"
                name="price"
                rules={[{ required: true, message: "Vui lòng nhập giá" }]}
              >
                <InputNumber min={0} style={{ width: "100%" }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Tồn kho" name="stock">
                <InputNumber min={0} style={{ width: "100%" }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Đơn vị" name="unit">
                <AutoComplete
                  options={unitSuggestions}
                  filterOption={(input, option) =>
                    (option?.value || "").toLowerCase().includes(input.toLowerCase())
                  }
                  placeholder="Ví dụ: kg, piece, box..."
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Ảnh sản phẩm" name="image">
            <Input
              placeholder="Dán URL ảnh hoặc dùng nút tải từ máy"
              onChange={(event) => setProductImagePreview(event.target.value)}
            />
          </Form.Item>

          <div className="admin-upload-row">
            <Upload
              accept="image/*"
              showUploadList={false}
              beforeUpload={(file) =>
                uploadImageToField(file, productForm, setProductImagePreview)
              }
            >
              <Button>Tải ảnh từ máy</Button>
            </Upload>
            <Typography.Text type="secondary">
              Có thể chọn ảnh từ máy thay cho nhập URL thủ công.
            </Typography.Text>
          </div>

          {productImagePreview ? (
            <div className="admin-image-preview-wrap">
              <img src={productImagePreview} alt="Xem trước sản phẩm" className="admin-image-preview" />
            </div>
          ) : null}

          <Form.Item label="Kích hoạt" name="isActive" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}

export default App;
