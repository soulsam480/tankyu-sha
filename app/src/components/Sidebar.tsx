import { Link } from "@tanstack/react-router";
import IconCloud from "~icons/carbon/cloud";
import IconMenu from "~icons/carbon/menu";
import IconChat from "~icons/carbon/chat";
import IconTask from "~icons/carbon/task";
import IconRun from "~icons/carbon/run";
import IconSettings from "~icons/carbon/settings";

export default function Sidebar() {
  return (
    <div className="w-72 bg-secondary-50 text-secondary-700 flex flex-col p-4">
      <div className="flex items-center justify-between p-2 mb-4">
        <div className="flex items-center">
          <IconCloud className="w-6 h-6 mr-2 text-primary-500" />
          <span className="text-xl font-semibold text-gray-800">
            Tankyu-Sha
          </span>
        </div>
        <button className="p-2 rounded-full hover:bg-secondary-200">
          <IconMenu className="w-5 h-5 text-gray-600" />
        </button>
      </div>

      <div className="px-2 mb-4">
        <button className="w-full flex items-center justify-center px-4 py-2 rounded-lg bg-primary-500 text-white hover:bg-primary-600">
          <IconChat className="mr-2" />
          New Chat
        </button>
      </div>

      <nav className="flex-1 px-2 py-4 space-y-2">
        <Link
          to="/tasks"
          className="flex items-center px-4 py-2 rounded-lg text-gray-700 hover:bg-secondary-200"
          activeProps={{ className: "bg-secondary-200 font-semibold" }}
        >
          <IconTask className="mr-3" />
          Tasks
        </Link>
        <Link
          to="/runs"
          className="flex items-center px-4 py-2 rounded-lg text-gray-700 hover:bg-secondary-200"
          activeProps={{ className: "bg-secondary-200 font-semibold" }}
        >
          <IconRun className="mr-3" />
          Runs
        </Link>
      </nav>

      <div className="border-t border-secondary-200 pt-4">
        <Link
          to="/settings"
          className="flex items-center px-4 py-2 rounded-lg text-gray-700 hover:bg-secondary-200"
          activeProps={{ className: "bg-secondary-200 font-semibold" }}
        >
          <IconSettings className="mr-3" />
          Settings
        </Link>
      </div>
    </div>
  );
}
