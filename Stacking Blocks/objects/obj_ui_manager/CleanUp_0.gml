// Recursively delete the flex panel tree when this object is destroyed
if (variable_global_exists("flexpanel_root") || self.flexpanel_root != undefined) {
    flexpanel_delete_node(flexpanel_root, true);
}