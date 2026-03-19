import User from "./user.model.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-here";

const toPublicUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  role: user.role,
  addresses: user.addresses,
});

/**
 * REGISTER user
 */
export const register = async (req, res) => {
  try {
    const { name, email, password, confirmPassword } = req.body;

    // Validate inputs
    if (!name || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ message: "Passwords do not match" });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }

    // Validate password strength
    if (password.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: hashedPassword,
      phone: "",
    });

    // Generate token
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, {
      expiresIn: "7d",
    });

    res.status(201).json({
      message: "User registered successfully",
      token,
      user: toPublicUser(user),
    });
  } catch (error) {
    console.error("Register error:", error);
    res.status(500).json({ message: "Server error during registration" });
  }
};

/**
 * LOGIN user
 */
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(400).json({ message: "Invalid email or password" });
    }

    // Compare passwords
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({ message: "Invalid email or password" });
    }

    // Generate token
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, {
      expiresIn: "7d",
    });

    res.json({
      message: "Login successful",
      token,
      user: toPublicUser(user),
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server error during login" });
  }
};

/**
 * GET current user
 */
export const getCurrentUser = async (req, res) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const user = await User.findById(userId).select('-password');

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(toPublicUser(user));
  } catch (error) {
    console.error("Get current user error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * CREATE user
 */
export const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, role, addresses } = req.body;
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ message: "name, email and password are required" });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      phone,
      role,
      addresses,
    });

    res.status(201).json(toPublicUser(user));
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * GET all users
 */
export const getUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password").sort({ createdAt: -1 });
    res.json(users.map(toPublicUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/**
 * GET user by ID
 */
export const getUserById = async (req, res) => {
  try {
    if (req.userId !== req.params.id) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const user = await User.findById(req.params.id).select('-password');
    if (!user)
      return res.status(404).json({ message: "User not found" });

    res.json(toPublicUser(user));
  } catch (error) {
    res.status(400).json({ message: "Invalid ID" });
  }
};

/**
 * UPDATE user
 */
export const updateUser = async (req, res) => {
  try {
    if (req.userId !== req.params.id) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const user = await User.findById(req.params.id);
    if (!user)
      return res.status(404).json({ message: "User not found" });

    const { password, email, ...safeFields } = req.body;
    Object.assign(user, safeFields);

    if (email) {
      user.email = email.toLowerCase();
    }

    if (password) {
      user.password = await bcrypt.hash(password, 10);
    }

    await user.save();

    res.json(toPublicUser(user));
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * DELETE user
 */
export const deleteUser = async (req, res) => {
  try {
    if (req.userId !== req.params.id) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const user = await User.findByIdAndDelete(req.params.id);
    if (!user)
      return res.status(404).json({ message: "User not found" });

    res.json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: "Invalid ID" });
  }
};
