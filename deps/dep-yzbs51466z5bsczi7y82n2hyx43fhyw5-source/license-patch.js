async function CheckLicense() {
    const ticketEnd = 8640000000000000;

    return {
        licenseType: 'lifetime',
        valid: true,
        requiresRefresh: false,
        status: 'normal',
        end: ticketEnd,
        refresh: ticketEnd,
        expiredIn: ticketEnd - Date.now()
    };
}
