import { Link } from "@tanstack/react-router";

export default function Sidebar() {
  return (
    <div className="w-64 bg-gray-800 text-white flex flex-col">
      <div className="p-4 font-bold text-lg">Tankyu-Sha</div>
      <nav className="flex-1 px-2 py-4 space-y-2">
        <Link to="/" className="block px-4 py-2 rounded hover:bg-gray-700">
          Tasks
        </Link>
        <Link to="/runs" className="block px-4 py-2 rounded hover:bg-gray-700">
          Runs
        </Link>
        <Link
          to="/settings"
          className="block px-4 py-2 rounded hover:bg-gray-700"
        >
          Settings
        </Link>
      </nav>
    </div>
  );
}
