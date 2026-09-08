#include <glib.h>

#include "my_application.h"

static void isolate_gdk_pixbuf_loaders() {
  if (g_getenv("GDK_PIXBUF_MODULE_FILE") != nullptr) {
    return;
  }

  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) {
    return;
  }

  g_autofree gchar* bundle_dir = g_path_get_dirname(executable);
  g_autofree gchar* cache = g_build_filename(
      bundle_dir, "lib", "gdk-pixbuf-2.0", "loaders.cache", nullptr);
  if (!g_file_test(cache, G_FILE_TEST_IS_REGULAR)) {
    return;
  }

  g_setenv("GDK_PIXBUF_MODULE_FILE", cache, TRUE);
}

int main(int argc, char** argv) {
  isolate_gdk_pixbuf_loaders();

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
