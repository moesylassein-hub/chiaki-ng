.pragma library

function visibleHosts(hosts, remote) {
    const routes = []
    for (const host of hosts) {
        if (!host.display)
            continue
        const psn = !!host.duid && !host.discovered
        if (psn === remote || (host.manual && !host.discovered))
            routes.push(host)
    }
    return routes
}

function indexOfRoute(hosts, routeId) {
    for (let i = 0; i < hosts.length; ++i) {
        if (hosts[i].routeId === routeId && hosts[i].display)
            return i
    }
    return -1
}
