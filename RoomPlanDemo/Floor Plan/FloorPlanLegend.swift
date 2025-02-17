import UIKit

class FloorPlanLegend: UIView {
    
    private struct LegendItem {
        let color: UIColor
        let label: String
    }
    
    // MARK: - Properties
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupItems()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func setupItems() {
        let items = [
            LegendItem(color: floorPlanSurfaceColor, label: "Wall"),
            LegendItem(color: doorColor, label: "Door"),
            LegendItem(color: windowColor, label: "Window"),
            LegendItem(color: openingColor, label: "Opening"),
            LegendItem(color: objectColor, label: "Object")
        ]
        
        items.forEach { item in
            let itemView = createItemView(for: item)
            stackView.addArrangedSubview(itemView)
        }
    }
    
    private func createItemView(for item: LegendItem) -> UIView {
        let container = UIView()
        
        // Color swatch
        let swatch = UIView()
        swatch.backgroundColor = item.color
        swatch.translatesAutoresizingMaskIntoConstraints = false
        
        // Label
        let label = UILabel()
        label.text = item.label
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(swatch)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            // Swatch constraints
            swatch.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            swatch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: 16),
            swatch.heightAnchor.constraint(equalToConstant: 16),
            
            // Label constraints
            label.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // Container constraints
            container.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
} 
