// Resource ids for the Server executable. Included from ServerResources.rc as
// well as from C++, so nothing in here may be anything but a #define.
#ifndef LINGYAO_SERVER_RESOURCES_H
#define LINGYAO_SERVER_RESOURCES_H

// The product mark. Id 1 on purpose: Windows shows the icon with the lowest id
// as the executable's own icon, so the Server gets the right icon in Task
// Manager for free rather than the blank default.
#define IDI_LINGYAO_LOGO 1

#endif // LINGYAO_SERVER_RESOURCES_H
