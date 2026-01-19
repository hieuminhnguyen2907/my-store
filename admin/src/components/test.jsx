import { useState } from "react";
import { categoryService } from "../services/category.service";

export default function CreateCategory() {
  const [name, setName] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    await categoryService.create({ name });
    alert("Created successfully");
    setName("");
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Category name"
      />
      <button type="submit">Create</button>
    </form>
  );
}
