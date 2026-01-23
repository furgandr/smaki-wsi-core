(() => {
  const shipFieldIds = [
    "account_ship_address1",
    "account_ship_address2",
    "account_ship_city",
    "account_ship_zipcode",
    "account_ship_country",
    "account_ship_state"
  ];
  const billFieldIds = [
    "account_bill_address1",
    "account_bill_address2",
    "account_bill_city",
    "account_bill_zipcode",
    "account_bill_country",
    "account_bill_state"
  ];

  const getCheckbox = () => document.getElementById("account_ship_same");

  const copyValue = (sourceId, targetId) => {
    const source = document.getElementById(sourceId);
    const target = document.getElementById(targetId);
    if (!source || !target) return;
    target.value = source.value;
    target.dispatchEvent(new Event("change", { bubbles: true }));
  };

  const syncShippingAddress = () => {
    const checkbox = getCheckbox();
    if (!checkbox || !checkbox.checked) return;
    billFieldIds.forEach((billId, index) => copyValue(billId, shipFieldIds[index]));
  };

  const toggleShippingFields = () => {
    const checkbox = getCheckbox();
    if (!checkbox) return;
    const disabled = checkbox.checked;
    shipFieldIds.forEach((id) => {
      const field = document.getElementById(id);
      if (field) field.disabled = disabled;
    });
    if (disabled) syncShippingAddress();
  };

  document.addEventListener("change", (event) => {
    if (event.target?.id === "account_ship_same") {
      toggleShippingFields();
      return;
    }
    if (billFieldIds.includes(event.target?.id)) {
      syncShippingAddress();
    }
  });

  document.addEventListener("input", (event) => {
    if (billFieldIds.includes(event.target?.id)) {
      syncShippingAddress();
    }
  });
})();
