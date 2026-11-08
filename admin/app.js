
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';

import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';

import {
  getFirestore,
  collection,
  doc,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';

import { firebaseConfig } from './firebase-config.js';

// --------------------------------------------------
// FIREBASE
// --------------------------------------------------

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const $ = id => document.getElementById(id);

let products = [];
let orders = [];
let customers = [];
let unsubscribers = [];
let currentPage = 'overview';

let productSearchValue = '';
let productCategoryValue = 'All';

const money = value =>
  '₱' + Number(value || 0).toLocaleString('en-PH', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });

const safe = value =>
  String(value ?? '').replace(/[&<>"']/g, character => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[character]));

const dateValue = timestamp => {
  if (timestamp?.toDate) return timestamp.toDate();
  if (timestamp instanceof Date) return timestamp;
  return null;
};

const formatDate = timestamp => {
  const date = dateValue(timestamp);

  return date
    ? date.toLocaleDateString('en-PH', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      })
    : '—';
};

const formatDateTime = timestamp => {
  const date = dateValue(timestamp);

  return date
    ? date.toLocaleString('en-PH', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: 'numeric',
        minute: '2-digit'
      })
    : '—';
};

function toast(message) {
  const element = $('toast');

  element.textContent = message;
  element.classList.add('show');

  setTimeout(() => element.classList.remove('show'), 2600);
}

function clearStreams() {
  unsubscribers.forEach(unsubscribe => unsubscribe());
  unsubscribers = [];
}

// --------------------------------------------------
// AUTHENTICATION
// --------------------------------------------------

$('loginForm').addEventListener('submit', async event => {
  event.preventDefault();

  $('loginMessage').textContent = 'Signing in...';

  try {
    await signInWithEmailAndPassword(
      auth,
      $('loginEmail').value.trim(),
      $('loginPassword').value
    );

    $('loginMessage').textContent = '';
  } catch (error) {
    $('loginMessage').textContent = error.message;
  }
});

onAuthStateChanged(auth, async user => {
  clearStreams();

  if (!user) {
    $('loginView').classList.remove('hidden');
    $('appView').classList.add('hidden');
    $('loginMessage').textContent = '';
    return;
  }

  try {
    const userDocument = await getDoc(doc(db, 'users', user.uid));

    if (!userDocument.exists() || userDocument.data().role !== 'admin') {
      await signOut(auth);
      $('loginMessage').textContent =
        'This account does not have administrator access.';
      return;
    }

    $('loginView').classList.add('hidden');
    $('appView').classList.remove('hidden');

    $('adminEmail').textContent = user.email || 'Administrator';

    streamData();

  } catch (error) {
    await signOut(auth);

    $('loginMessage').textContent =
      'Could not verify admin access: ' + error.message;
  }
});

$('logoutBtn').onclick = async () => {
  try {
    await signOut(auth);
    toast('Signed out successfully.');
  } catch (error) {
    toast(error.message);
  }
};

// --------------------------------------------------
// REAL-TIME FIRESTORE DATA
// --------------------------------------------------

function streamData() {
  clearStreams();

  unsubscribers.push(
    onSnapshot(
      collection(db, 'products'),
      snapshot => {
        products = snapshot.docs.map(document => ({
          id: document.id,
          ...document.data()
        }));

        render();
      },
      error => toast('Products: ' + error.message)
    )
  );

  unsubscribers.push(
    onSnapshot(
      query(
        collection(db, 'orders'),
        orderBy('createdAt', 'desc')
      ),
      snapshot => {
        orders = snapshot.docs.map(document => ({
          id: document.id,
          ...document.data()
        }));

        render();
      },
      error => toast('Orders: ' + error.message)
    )
  );

  unsubscribers.push(
    onSnapshot(
      collection(db, 'users'),
      snapshot => {
        customers = snapshot.docs
          .map(document => ({
            id: document.id,
            ...document.data()
          }))
          .filter(user => user.role !== 'admin');

        render();
      },
      error => toast('Customers: ' + error.message)
    )
  );
}

// --------------------------------------------------
// NAVIGATION
// --------------------------------------------------

document.querySelectorAll('.nav[data-page]').forEach(button => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.nav[data-page]').forEach(item => {
      item.classList.remove('active');
    });

    button.classList.add('active');
    currentPage = button.dataset.page;

    render();
  });
});

// --------------------------------------------------
// GENERAL HELPERS
// --------------------------------------------------

function emptyState(message, icon = '▣') {
  return `
    <div class="empty-state">
      <div class="empty-icon">${icon}</div>
      <h3>${safe(message)}</h3>
      <p>There is currently no information to display.</p>
    </div>
  `;
}

function statusClass(status) {
  const value = String(status || 'Pending')
    .toLowerCase()
    .replace(/\s+/g, '-');

  if (value === 'completed') return 'status-completed';
  if (value === 'confirmed') return 'status-confirmed';
  if (value === 'processing') return 'status-processing';
  if (value === 'ready-for-pickup') return 'status-ready';
  if (value === 'cancelled') return 'status-cancelled';

  return 'status-pending';
}

function getRevenue() {
  return orders
    .filter(order => (order.orderStatus || 'Pending') !== 'Cancelled')
    .reduce((total, order) => {
      return total + Number(order.totalAmount || 0);
    }, 0);
}

function getPendingOrders() {
  return orders.filter(order =>
    ['Pending', 'Confirmed', 'Processing'].includes(
      order.orderStatus || 'Pending'
    )
  ).length;
}

function getLowStock() {
  return products.filter(product =>
    Number(product.stock || 0) <= 5
  );
}

function getOrderItems(order) {
  if (!Array.isArray(order.items)) return [];

  return order.items;
}

// --------------------------------------------------
// MAIN RENDERER
// --------------------------------------------------

function render() {
  if ($('appView').classList.contains('hidden')) return;

  const titles = {
    overview: 'Overview',
    products: 'Products',
    orders: 'Orders',
    customers: 'Customers'
  };

  $('pageTitle').textContent = titles[currentPage] || 'Overview';

  if (currentPage === 'overview') {
    renderOverview();
  }

  if (currentPage === 'products') {
    renderProducts();
  }

  if (currentPage === 'orders') {
    renderOrders();
  }

  if (currentPage === 'customers') {
    renderCustomers();
  }

  wireCommonActions();
}

// --------------------------------------------------
// OVERVIEW DASHBOARD
// --------------------------------------------------

function renderOverview() {
  const pending = getPendingOrders();
  const lowStock = getLowStock();

  $('pageContent').innerHTML = `
    <div class="welcome-banner">
      <div>
        <span class="welcome-label">TECHFORGE MANAGEMENT</span>
        <h2>Welcome to your control center.</h2>
        <p>Monitor your products, inventory, and customer orders.</p>
      </div>
      <div class="welcome-symbol">TF</div>
    </div>

    <div class="stats">
      <article class="stat">
        <div class="stat-top">
          <span>Total Revenue</span>
          <span class="stat-icon">₱</span>
        </div>
        <strong>${money(getRevenue())}</strong>
        <small>Non-cancelled orders</small>
      </article>

      <article class="stat">
        <div class="stat-top">
          <span>Total Products</span>
          <span class="stat-icon">▣</span>
        </div>
        <strong>${products.length}</strong>
        <small>Products in catalog</small>
      </article>

      <article class="stat">
        <div class="stat-top">
          <span>Total Orders</span>
          <span class="stat-icon">▤</span>
        </div>
        <strong>${orders.length}</strong>
        <small>Customer purchases</small>
      </article>

      <article class="stat">
        <div class="stat-top">
          <span>Customers</span>
          <span class="stat-icon">♙</span>
        </div>
        <strong>${customers.length}</strong>
        <small>Registered accounts</small>
      </article>
    </div>

    <div class="overview-grid">
      <section class="panel">
        <div class="panel-head">
          <div>
            <h2>Sales overview</h2>
            <p class="muted">Order revenue over the last 7 days</p>
          </div>
          <span class="pill">Last 7 days</span>
        </div>

        ${renderSalesChart()}
      </section>

      <section class="panel">
        <div class="panel-head">
          <div>
            <h2>Order summary</h2>
            <p class="muted">Current order activity</p>
          </div>
        </div>

        <div class="summary-list">
          <div>
            <span class="summary-dot pending"></span>
            <span>Pending / In progress</span>
            <strong>${pending}</strong>
          </div>

          <div>
            <span class="summary-dot completed"></span>
            <span>Completed</span>
            <strong>${orders.filter(o => o.orderStatus === 'Completed').length}</strong>
          </div>

          <div>
            <span class="summary-dot cancelled"></span>
            <span>Cancelled</span>
            <strong>${orders.filter(o => o.orderStatus === 'Cancelled').length}</strong>
          </div>
        </div>

        <div class="summary-total">
          <span>Inventory items</span>
          <strong>${products.reduce((sum, p) => sum + Number(p.stock || 0), 0)}</strong>
        </div>
      </section>
    </div>

    <section class="panel">
      <div class="panel-head">
        <div>
          <h2>Recent orders</h2>
          <p class="muted">Latest purchases from your customers</p>
        </div>
        <button class="secondary" data-goto="orders">View all orders →</button>
      </div>

      ${renderOrderTable(orders.slice(0, 6), false)}
    </section>

    <section class="panel">
      <div class="panel-head">
        <div>
          <h2>Inventory alerts</h2>
          <p class="muted">Products that need restocking</p>
        </div>
        <span class="pill">${lowStock.length} items</span>
      </div>

      ${renderLowStockTable(lowStock)}
    </section>
  `;
}

function renderSalesChart() {
  const days = [];

  for (let i = 6; i >= 0; i--) {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() - i);

    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);

    const total = orders
      .filter(order => {
        const orderDate = dateValue(order.createdAt);

        return orderDate &&
          orderDate >= date &&
          orderDate < nextDay &&
          order.orderStatus !== 'Cancelled';
      })
      .reduce((sum, order) => sum + Number(order.totalAmount || 0), 0);

    days.push({
      label: date.toLocaleDateString('en-PH', { weekday: 'short' }),
      total
    });
  }

  const maximum = Math.max(...days.map(day => day.total), 1);

  return `
    <div class="sales-chart">
      ${days.map(day => {
        const height = Math.max((day.total / maximum) * 100, 4);

        return `
          <div class="chart-column">
            <div class="chart-value">${day.total ? money(day.total) : '—'}</div>
            <div class="chart-track">
              <div class="chart-bar" style="height:${height}%"></div>
            </div>
            <span>${day.label}</span>
          </div>
        `;
      }).join('')}
    </div>

    <div class="chart-footer">
      <span>7-day order revenue</span>
      <strong>${money(days.reduce((sum, day) => sum + day.total, 0))}</strong>
    </div>
  `;
}

// --------------------------------------------------
// PRODUCTS PAGE
// --------------------------------------------------

function renderProducts() {
  const categories = [
    'All',
    ...new Set(
      products.map(product => product.category).filter(Boolean)
    )
  ];

  $('pageContent').innerHTML = `
    <div class="page-intro">
      <div>
        <h2>Product inventory</h2>
        <p>Manage your computer parts catalog and stock levels.</p>
      </div>

      <button id="addProduct" class="primary">＋ Add new product</button>
    </div>

    <section class="panel">
      <div class="product-toolbar">
        <div class="search-row">
          <input
            id="productSearch"
            value="${safe(productSearchValue)}"
            placeholder="Search products, brands, categories..."
          >
        </div>

        <select id="categoryFilter">
          ${categories.map(category => `
            <option
              value="${safe(category)}"
              ${category === productCategoryValue ? 'selected' : ''}
            >
              ${safe(category === 'All' ? 'All categories' : category)}
            </option>
          `).join('')}
        </select>
      </div>

      <div class="inventory-summary">
        <span>${products.length} products found</span>
        <span>${products.reduce((sum, p) => sum + Number(p.stock || 0), 0)} total units in stock</span>
      </div>

      <div id="productGrid" class="product-grid">
        ${renderProductCards(getFilteredProducts())}
      </div>
    </section>
  `;

  $('addProduct').onclick = () => openProduct();

  $('productSearch').oninput = event => {
    productSearchValue = event.target.value;
    updateProductGrid();
  };

  $('categoryFilter').onchange = event => {
    productCategoryValue = event.target.value;
    updateProductGrid();
  };

  wireProductActions();
}

function getFilteredProducts() {
  return products.filter(product => {
    const searchText = (
      product.productName + ' ' +
      product.brand + ' ' +
      product.category + ' ' +
      product.description
    ).toLowerCase();

    const matchesSearch = searchText.includes(
      productSearchValue.toLowerCase()
    );

    const matchesCategory =
      productCategoryValue === 'All' ||
      product.category === productCategoryValue;

    return matchesSearch && matchesCategory;
  });
}

function updateProductGrid() {
  const grid = $('productGrid');

  if (!grid) return;

  grid.innerHTML = renderProductCards(getFilteredProducts());

  const count = $('pageContent').querySelector('.inventory-summary span');

  if (count) {
    count.textContent = `${getFilteredProducts().length} products found`;
  }

  wireProductActions();
}

function renderProductCards(list) {
  if (!list.length) {
    return emptyState('No products found', '▣');
  }

  return list.map(product => {
    const stock = Number(product.stock || 0);

    let stockLabel = 'In stock';
    let stockClass = 'stock-good';

    if (stock <= 0) {
      stockLabel = 'Out of stock';
      stockClass = 'stock-out';
    } else if (stock <= 5) {
      stockLabel = 'Low stock';
      stockClass = 'stock-low';
    }

    const image = product.imageUrl
      ? `<img src="${safe(product.imageUrl)}" alt="${safe(product.productName)}" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='grid'">`
      : '';

    return `
      <article class="product-card">
        <div class="product-image">
          ${image}
          <div class="image-placeholder" style="${product.imageUrl ? 'display:none' : ''}">▣</div>
          <span class="product-category">${safe(product.category || 'Uncategorized')}</span>
        </div>

        <div class="product-info">
          <span class="product-brand">${safe(product.brand || 'Generic')}</span>

          <h3>${safe(product.productName || 'Unnamed product')}</h3>

          <p class="product-description">
            ${safe(product.description || 'No product description available.')}
          </p>

          <div class="product-bottom">
            <strong>${money(product.price)}</strong>
            <span class="stock-label ${stockClass}">${stockLabel}</span>
          </div>

          <div class="product-meta">
            <span>Stock: <b>${stock}</b></span>
            <span>${safe(product.id.slice(-6).toUpperCase())}</span>
          </div>

          <div class="product-actions">
            <button class="secondary" data-edit="${safe(product.id)}">Edit</button>
            <button class="text-btn danger" data-delete="${safe(product.id)}">Delete</button>
          </div>
        </div>
      </article>
    `;
  }).join('');
}

// --------------------------------------------------
// ORDERS PAGE
// --------------------------------------------------

function renderOrders() {
  $('pageContent').innerHTML = `
    <div class="page-intro">
      <div>
        <h2>Order management</h2>
        <p>Review customer purchases and manage order progress.</p>
      </div>
    </div>

    <div class="stats order-stats">
      <article class="stat">
        <span>Total orders</span>
        <strong>${orders.length}</strong>
        <small>All customer orders</small>
      </article>

      <article class="stat">
        <span>Pending</span>
        <strong>${orders.filter(o => (o.orderStatus || 'Pending') === 'Pending').length}</strong>
        <small>Awaiting confirmation</small>
      </article>

      <article class="stat">
        <span>Processing</span>
        <strong>${orders.filter(o => o.orderStatus === 'Processing').length}</strong>
        <small>Being prepared</small>
      </article>

      <article class="stat">
        <span>Completed</span>
        <strong>${orders.filter(o => o.orderStatus === 'Completed').length}</strong>
        <small>Finished orders</small>
      </article>
    </div>

    <section class="panel">
      <div class="panel-head">
        <div>
          <h2>All customer orders</h2>
          <p class="muted">Update the status of each purchase.</p>
        </div>
      </div>

      ${renderOrderTable(orders, true)}
    </section>
  `;

  wireOrderActions();
}

function renderOrderTable(list, showDetails = true) {
  if (!list.length) {
    return emptyState('No orders available', '▤');
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Order ID</th>
            <th>Customer</th>
            <th>Date</th>
            <th>Payment</th>
            <th>Total</th>
            <th>Status</th>
            <th>Update</th>
          </tr>
        </thead>

        <tbody>
          ${list.map(order => `
            <tr>
              <td>
                <b>#${safe(order.id.slice(-7).toUpperCase())}</b>
                ${showDetails ? `<small>${getOrderItems(order).length} item types</small>` : ''}
              </td>

              <td>
                <b>${safe(order.customerName || '—')}</b>
                <small>${safe(order.contactNumber || '')}</small>
              </td>

              <td>${formatDate(order.createdAt)}</td>

              <td>${safe(order.paymentMethod || '—')}</td>

              <td><b>${money(order.totalAmount)}</b></td>

              <td>
                <span class="status-badge ${statusClass(order.orderStatus)}">
                  ${safe(order.orderStatus || 'Pending')}
                </span>
              </td>

              <td>
                <select data-status="${safe(order.id)}">
                  ${[
                    'Pending',
                    'Confirmed',
                    'Processing',
                    'Ready for Pickup',
                    'Completed',
                    'Cancelled'
                  ].map(status => `
                    <option
                      value="${status}"
                      ${status === (order.orderStatus || 'Pending') ? 'selected' : ''}
                    >
                      ${status}
                    </option>
                  `).join('')}
                </select>
              </td>
            </tr>

            ${showDetails ? `
              <tr class="order-detail-row">
                <td colspan="7">
                  <details class="order-details">
                    <summary>View order details</summary>

                    <div class="order-detail-content">
                      <div>
                        <span>Delivery address</span>
                        <p>${safe(order.deliveryAddress || 'Not provided')}</p>
                      </div>

                      <div>
                        <span>Order items</span>
                        ${getOrderItems(order).map(item => `
                          <p>
                            ${safe(item.productName || 'Product')}
                            × ${Number(item.quantity || 0)}
                            — ${money(Number(item.price || 0) * Number(item.quantity || 0))}
                          </p>
                        `).join('') || '<p>No item details available.</p>'}
                      </div>
                    </div>
                  </details>
                </td>
              </tr>
            ` : ''}
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

// --------------------------------------------------
// LOW STOCK
// --------------------------------------------------

function renderLowStockTable(list) {
  if (!list.length) {
    return emptyState('All products have sufficient stock', '✓');
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Category</th>
            <th>Available stock</th>
            <th>Price</th>
          </tr>
        </thead>

        <tbody>
          ${list.map(product => `
            <tr>
              <td>
                <b>${safe(product.productName)}</b>
                <small>${safe(product.brand || '')}</small>
              </td>

              <td>${safe(product.category || '—')}</td>

              <td>
                <span class="stock-label ${Number(product.stock) <= 0 ? 'stock-out' : 'stock-low'}">
                  ${Number(product.stock || 0)} units
                </span>
              </td>

              <td>${money(product.price)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

// --------------------------------------------------
// CUSTOMERS PAGE
// --------------------------------------------------

function renderCustomers() {
  $('pageContent').innerHTML = `
    <div class="page-intro">
      <div>
        <h2>Customer directory</h2>
        <p>View registered TechForge customer accounts.</p>
      </div>
    </div>

    <div class="stats">
      <article class="stat">
        <span>Total customers</span>
        <strong>${customers.length}</strong>
        <small>Registered accounts</small>
      </article>

      <article class="stat">
        <span>Customers with orders</span>
        <strong>${customers.filter(customer =>
          orders.some(order => order.userId === customer.id)
        ).length}</strong>
        <small>Have placed purchases</small>
      </article>

      <article class="stat">
        <span>Total orders</span>
        <strong>${orders.length}</strong>
        <small>Across all customers</small>
      </article>

      <article class="stat">
        <span>Completed orders</span>
        <strong>${orders.filter(order => order.orderStatus === 'Completed').length}</strong>
        <small>Successfully completed</small>
      </article>
    </div>

    <section class="panel">
      <div class="panel-head">
        <div>
          <h2>Registered customers</h2>
          <p class="muted">Customer account information</p>
        </div>
      </div>

      <div class="search-row">
        <input id="customerSearch" placeholder="Search customer name or email...">
      </div>

      <div id="customerTable">
        ${renderCustomerTable(customers)}
      </div>
    </section>
  `;

  $('customerSearch').oninput = event => {
    const search = event.target.value.toLowerCase();

    const filtered = customers.filter(customer =>
      `${customer.fullName || ''} ${customer.email || ''} ${customer.phoneNumber || ''}`
        .toLowerCase()
        .includes(search)
    );

    $('customerTable').innerHTML = renderCustomerTable(filtered);
  };
}

function renderCustomerTable(list) {
  if (!list.length) {
    return emptyState('No customers found', '♙');
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Customer</th>
            <th>Email</th>
            <th>Phone number</th>
            <th>Total orders</th>
            <th>Account status</th>
          </tr>
        </thead>

        <tbody>
          ${list.map(customer => {
            const customerOrders = orders.filter(
              order => order.userId === customer.id
            );

            return `
              <tr>
                <td>
                  <div class="customer-cell">
                    <div class="customer-avatar">
                      ${safe((customer.fullName || 'C').charAt(0).toUpperCase())}
                    </div>

                    <div>
                      <b>${safe(customer.fullName || 'Unnamed customer')}</b>
                      <small>Customer account</small>
                    </div>
                  </div>
                </td>

                <td>${safe(customer.email || '—')}</td>

                <td>${safe(customer.phoneNumber || '—')}</td>

                <td><b>${customerOrders.length}</b></td>

                <td><span class="status-badge status-completed">Registered</span></td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

// --------------------------------------------------
// PRODUCT CRUD
// --------------------------------------------------

function openProduct(product = null) {
  $('productForm').reset();

  $('productId').value = product?.id || '';
  $('productName').value = product?.productName || '';
  $('productBrand').value = product?.brand || '';
  $('productCategory').value = product?.category || '';
  $('productPrice').value = product?.price ?? '';
  $('productStock').value = product?.stock ?? '';
  $('productImage').value = product?.imageUrl || '';
  $('productDescription').value = product?.description || '';

  $('productMessage').textContent = '';

  $('productDialogTitle').textContent =
    product ? 'Edit product' : 'Add new product';

  $('productDialog').showModal();
}

function wireProductActions() {
  document.querySelectorAll('[data-edit]').forEach(button => {
    button.onclick = () => {
      const product = products.find(item => item.id === button.dataset.edit);

      if (product) openProduct(product);
    };
  });

  document.querySelectorAll('[data-delete]').forEach(button => {
    button.onclick = async () => {
      const product = products.find(item => item.id === button.dataset.delete);

      if (!product) return;

      if (!confirm(`Are you sure you want to delete "${product.productName}"?`)) {
        return;
      }

      try {
        await deleteDoc(doc(db, 'products', product.id));
        toast('Product deleted successfully.');
      } catch (error) {
        toast('Could not delete product: ' + error.message);
      }
    };
  });
}

$('closeProduct').onclick = () => $('productDialog').close();
$('cancelProduct').onclick = () => $('productDialog').close();

$('productForm').addEventListener('submit', async event => {
  event.preventDefault();

  const id = $('productId').value;

  const price = Number($('productPrice').value);
  const stock = Number($('productStock').value);

  if (!Number.isFinite(price) || price < 0) {
    $('productMessage').textContent = 'Enter a valid product price.';
    return;
  }

  if (!Number.isInteger(stock) || stock < 0) {
    $('productMessage').textContent = 'Stock must be a non-negative whole number.';
    return;
  }

  const imageUrl = $('productImage').value.trim();

  if (imageUrl && !/^https?:\/\/\S+$/i.test(imageUrl)) {
    $('productMessage').textContent = 'Enter a valid HTTP or HTTPS image URL.';
    return;
  }

  const data = {
    productName: $('productName').value.trim(),
    brand: $('productBrand').value.trim(),
    category: $('productCategory').value.trim(),
    price,
    stock,
    imageUrl,
    description: $('productDescription').value.trim(),
    updatedAt: serverTimestamp()
  };

  if (!data.productName || !data.brand || !data.category) {
    $('productMessage').textContent = 'Please complete all required fields.';
    return;
  }

  try {
    if (id) {
      await updateDoc(doc(db, 'products', id), data);
      toast('Product updated successfully.');
    } else {
      await addDoc(collection(db, 'products'), {
        ...data,
        createdAt: serverTimestamp()
      });

      toast('Product added successfully.');
    }

    $('productDialog').close();

  } catch (error) {
    $('productMessage').textContent = error.message;
  }
});

// --------------------------------------------------
// ORDER STATUS UPDATES
// --------------------------------------------------

function wireOrderActions() {
  document.querySelectorAll('[data-status]').forEach(select => {
    select.onchange = async () => {
      const orderId = select.dataset.status;
      const newStatus = select.value;

      try {
        await updateDoc(doc(db, 'orders', orderId), {
          orderStatus: newStatus,
          updatedAt: serverTimestamp()
        });

        toast('Order status updated successfully.');

      } catch (error) {
        toast('Could not update order: ' + error.message);
      }
    };
  });
}

// --------------------------------------------------
// SHARED PAGE ACTIONS
// --------------------------------------------------

function wireCommonActions() {
  document.querySelectorAll('[data-goto]').forEach(button => {
    button.onclick = () => {
      const target = document.querySelector(
        `[data-page="${button.dataset.goto}"]`
      );

      if (target) target.click();
    };
  });

  wireProductActions();
  wireOrderActions();
}
