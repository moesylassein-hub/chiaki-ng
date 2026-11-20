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

function dashboardHosts(hosts, registrations, remote) {
    const routes = visibleHosts(hosts, remote)
    if (remote)
        return routes
    const available = new Set(routes.filter(h => h.registered && h.mac).map(h => h.mac))
    for (const console of registrations) {
        if (available.has(console.mac))
            continue
        routes.push({routeId: "registered/" + console.mac, registered: true, display: true,
                     offline: true, mac: console.mac, name: console.name, ps5: console.ps5})
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

function consoleCards(hosts, registrations) {
    const consoles = new Map()
    const byName = new Map()
    for (const saved of registrations) {
        const id = "registered/" + saved.mac
        consoles.set(id, {id, mac:saved.mac, name:saved.name, ps5:saved.ps5, registered:true,
                          local:[], remote:[], app:"", history:[], state:"offline"})
        const names = byName.get(saved.name) || []
        names.push(id)
        byName.set(saved.name, names)
    }
    for (const host of hosts) {
        if (!host.display) continue
        const isRemote = !!host.duid && !host.discovered
        const matches = byName.get(host.name) || []
        const id = host.registered && host.mac ? "registered/" + host.mac :
                   isRemote && matches.length === 1 ? matches[0] : host.routeId
        if (!consoles.has(id))
            consoles.set(id, {id, mac:host.mac || "", name:host.name || host.address,
                              ps5:host.ps5 !== false, registered:!!host.registered,
                              local:[], remote:[], app:"", history:[], state:"offline"})
        const card = consoles.get(id)
        if (!isRemote) card.local.push(host)
        if (isRemote || (host.manual && !host.discovered)) card.remote.push(host)
        if (host.discovered) { card.state = host.state; card.app = host.app || "" }
        if (host.recentGames?.length) card.history = host.recentGames
    }
    return Array.from(consoles.values())
}
